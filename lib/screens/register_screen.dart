import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';
import '../services/language_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const String baseUrl = 'http://192.168.1.14:8000/api';

  @override
  void initState() {
    super.initState();
    LanguageService.onLocaleChanged = () {
      if (mounted) setState(() {});
    };

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    LanguageService.onLocaleChanged = null;
    super.dispose();
  }

  // Fonction de validation du téléphone tunisien
  String? _validatePhoneNumber(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Le numéro de téléphone est obligatoire';
    }

    // Enlever les espaces et les tirets
    String cleanedPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');

    // Vérifier si le numéro commence par +216
    if (cleanedPhone.startsWith('+216')) {
      cleanedPhone = cleanedPhone.substring(4); // Enlever +216
    }

    // Vérifier si le numéro commence par 00216
    if (cleanedPhone.startsWith('00216')) {
      cleanedPhone = cleanedPhone.substring(5); // Enlever 00216
    }

    // Vérifier si le numéro commence par 0 (09...)
    if (cleanedPhone.startsWith('0')) {
      cleanedPhone = cleanedPhone.substring(1);
    }

    // Vérifier que le numéro contient exactement 8 chiffres
    if (!RegExp(r'^\d{8}$').hasMatch(cleanedPhone)) {
      return 'Le numéro doit contenir exactement 8 chiffres (ex: 12345678)';
    }

    // Vérifier que le numéro commence par un indicatif valide (Tunisie)
    final firstTwoDigits = cleanedPhone.substring(0, 2);
    const validPrefixes = [
      '20',
      '21',
      '22',
      '23',
      '24',
      '25',
      '26',
      '27',
      '28',
      '29',
      '50',
      '51',
      '52',
      '53',
      '54',
      '55',
      '56',
      '57',
      '58',
      '59',
      '90',
      '91',
      '92',
      '93',
      '94',
      '95',
      '96',
      '97',
      '98',
      '99',
    ];

    if (!validPrefixes.contains(firstTwoDigits)) {
      return 'Indicatif tunisien invalide (20-29, 50-59, 90-99)';
    }

    return null;
  }

  // Fonction pour formater l'affichage du téléphone
  String _formatPhoneForDisplay(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('+216')) {
      return cleaned;
    }
    if (cleaned.startsWith('00216')) {
      return '+${cleaned.substring(2)}';
    }
    if (cleaned.startsWith('0') && cleaned.length == 9) {
      return '+216${cleaned.substring(1)}';
    }
    if (cleaned.length == 8) {
      return '+216$cleaned';
    }
    return phone;
  }

  // Fonction pour formater le téléphone avant envoi API
  String _formatPhoneForApi(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');

    if (cleaned.startsWith('+216')) {
      return cleaned;
    }
    if (cleaned.startsWith('00216')) {
      return '+${cleaned.substring(2)}';
    }
    if (cleaned.startsWith('0')) {
      return '+216${cleaned.substring(1)}';
    }
    if (cleaned.length == 8 && RegExp(r'^\d+$').hasMatch(cleaned)) {
      return '+216$cleaned';
    }
    return cleaned;
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final password = _passwordController.text.trim();
    final passwordConfirmation = _passwordConfirmationController.text.trim();

    if (password != passwordConfirmation) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Le mot de passe et sa confirmation ne correspondent pas'),
                backgroundColor: Colors.red[700],
            ),
        );
        return;
    }

    setState(() => _isLoading = true);

    try {
        final formattedPhone = _formatPhoneForApi(_phoneController.text.trim());

        final response = await http.post(
            Uri.parse('$baseUrl/register'),
            headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode({
                'name': _nameController.text.trim(),
                'email': _emailController.text.trim(),
                'password': _passwordController.text,
                'password_confirmation': _passwordConfirmationController.text,
                'phone': formattedPhone,
            }),
        );


        final data = jsonDecode(response.body);

        setState(() => _isLoading = false);

        if (response.statusCode == 200 || response.statusCode == 201) {
            if (data['token'] != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('token', data['token']);
                await prefs.setString('user_name', _nameController.text.trim());
                await prefs.setString('user_email', _emailController.text.trim());
                await prefs.setString('user_phone', formattedPhone);
                
                // ✅ حفظ IPP - الجزء المهم
                if (data['ipp'] != null) {
                    await prefs.setString('ipp', data['ipp'].toString());
                    print('✅ IPP sauvegardé: ${data['ipp']}');
                } else if (data['user'] != null) {
                    if (data['user']['ipp'] != null) {
                        await prefs.setString('ipp', data['user']['ipp'].toString());
                        print('✅ IPP sauvegardé depuis user: ${data['user']['ipp']}');
                    }
                    // حفظ معلومات إضافية من user
                    if (data['user']['id'] != null) {
                        await prefs.setInt('user_id', data['user']['id']);
                    }
                    if (data['user']['doctor_id'] != null) {
                        await prefs.setInt('doctor_id', data['user']['doctor_id']);
                    }
                }
                
                // حفظ البريد الإلكتروني من الـ response إذا كان موجود
                final user = data['user'] ?? data['data']?['user'];
                if (user is Map<String, dynamic>) {
                    final phone = user['phone'];
                    if (phone != null && phone.toString().isNotEmpty) {
                        await prefs.setString('user_phone', phone.toString());
                    }
                    final birth = user['birth_date'] ?? user['birth'] ?? user['date_of_birth'];
                    if (birth != null) {
                        await prefs.setString('birthDate', birth.toString());
                    }
                    final email = user['email'];
                    if (email != null && email.toString().isNotEmpty) {
                        await prefs.setString('user_email', email.toString());
                    }
                }
            }

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppTranslations.translate(context, 'registration_success')),
                    backgroundColor: Colors.green,
                ),
            );

            Navigator.of(context).pop();
        } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(data['message'] ?? AppTranslations.translate(context, 'error')),
                    backgroundColor: Colors.red[700],
                ),
            );
        }
    } catch (e) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Network error: $e'),
                backgroundColor: Colors.red[700],
            ),
        );
    }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 23, 95, 114),
              Color.fromARGB(255, 23, 95, 114),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Form(
          key: _formKey,
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppTranslations.translate(context, 'app_name'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppTranslations.translate(context, 'create_account'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 40),

                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppTranslations.translate(context, 'sign_up'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _nameController,
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return 'Nom obligatoire';
                                if (value.length < 3) return 'Nom trop court';
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Nom complet',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: Color.fromARGB(255, 23, 95, 114),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 23, 95, 114),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return 'Email obligatoire';
                                final emailRegex = RegExp(
                                  r'^[\w\.-]+@[\w\.-]+\.\w+$',
                                );
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Email invalide';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: AppTranslations.translate(
                                  context,
                                  'email',
                                ),
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Color.fromARGB(255, 23, 95, 114),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 23, 95, 114),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: (v) {
                                final value = v ?? '';
                                if (value.trim().isEmpty) {
                                  return 'Mot de passe obligatoire';
                                }
                                if (value.trim().length < 8) {
                                  return 'Mot de passe trop court (min 8)';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: AppTranslations.translate(
                                  context,
                                  'password',
                                ),
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: Color.fromARGB(255, 23, 95, 114),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey[400],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 23, 95, 114),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passwordConfirmationController,
                              obscureText: _obscurePassword,
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) {
                                  return 'Confirmation obligatoire';
                                }
                                if (value != _passwordController.text.trim()) {
                                  return 'Les mots de passe ne correspondent pas';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: AppTranslations.translate(
                                  context,
                                  'password_confirmation',
                                ),
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: Color.fromARGB(255, 23, 95, 114),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 23, 95, 114),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              validator: _validatePhoneNumber,
                              onChanged: (value) {
                                // Auto-formatage pendant la saisie
                                if (value.length == 8 &&
                                    !value.startsWith('+')) {
                                  _phoneController.value = TextEditingValue(
                                    text: '+216$value',
                                    selection: TextSelection.collapsed(
                                      offset: '+216$value'.length,
                                    ),
                                  );
                                }
                              },
                              decoration: InputDecoration(
                                hintText: '+216 12 345 678',
                                helperText:
                                    'Format: +216 suivi de 8 chiffres (ex: +21612345678)',
                                helperStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(
                                  Icons.phone_outlined,
                                  color: Color.fromARGB(255, 23, 95, 114),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 23, 95, 114),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    23,
                                    95,
                                    114,
                                  ),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        AppTranslations.translate(
                                          context,
                                          'create_account',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Colors.grey[300]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Or continue with',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Colors.grey[300]),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: TextButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Google login coming soon',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.g_mobiledata,
                                        size: 24,
                                        color: Color.fromARGB(255, 23, 95, 114),
                                      ),
                                      label: const Text(
                                        'Google',
                                        style: TextStyle(
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: TextButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Facebook login coming soon',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.facebook,
                                        color: Color.fromARGB(255, 23, 95, 114),
                                      ),
                                      label: const Text(
                                        'Facebook',
                                        style: TextStyle(
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppTranslations.translate(
                              context,
                              'already_have_account',
                            ),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text(
                              ' ${AppTranslations.translate(context, 'sign_in')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

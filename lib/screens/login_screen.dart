import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';
import '../services/language_service.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const String baseUrl = 'http://192.168.1.14:8000/api';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    LanguageService.onLocaleChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    LanguageService.onLocaleChanged = null;
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslations.translate(context, 'error'))),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      print('=== LOGIN RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Response: $data');

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();

        // ✅ NETTOYAGE: Supprimer les données du compte précédent
        await prefs.remove('latest_systolic');
        await prefs.remove('latest_diastolic');
        await prefs.remove('latest_glycemie');
        await prefs.remove('latest_temperature');
        await prefs.remove('latest_pulse');
        await prefs.remove('latest_oxygenie');
        await prefs.remove('latest_record_date');
        await prefs.remove('latest_status');
        await prefs.remove('temp_report_data');
        await prefs.remove('medications_cache');
        print('✅ Anciennes données santé supprimées');

        // Token
        final token = data['token'];
        if (token != null) {
          await prefs.setString('token', token.toString());
          await prefs.setString('access_token', token.toString());
        }

        // User info
        final user = data['user'];
        if (user != null) {
          if (user['name'] != null) {
            await prefs.setString('user_name', user['name'].toString());
          }
          if (user['email'] != null) {
            await prefs.setString('user_email', user['email'].toString());
          }
          if (user['id'] != null) {
            await prefs.setInt('user_id', (user['id'] as num).toInt());
          }
          if (user['phone'] != null) {
            await prefs.setString('user_phone', user['phone'].toString());
          }
          if (user['role'] != null) {
            await prefs.setString('user_role', user['role'].toString());
          }

          if (user['doctor_id'] != null) {
            await prefs.setInt('doctor_id', (user['doctor_id'] as num).toInt());
            print('✅ Doctor ID saved: ${user['doctor_id']}');
          } else {
            print('⚠️ No doctor_id in user data');
          }
        }

        // IPP
        final ipp = data['ipp'] ?? user?['ipp'];
        if (ipp != null && ipp.toString().isNotEmpty) {
          await prefs.setString('ipp', ipp.toString());
          print('✅ IPP saved: $ipp');
        }

        // Vérification
        final savedDoctorId = await prefs.getInt('doctor_id');
        print('=== VERIFICATION ===');
        print('Doctor ID in SharedPreferences: $savedDoctorId');
        print('User ID: ${await prefs.getInt('user_id')}');
        print('User Name: ${await prefs.getString('user_name')}');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.translate(context, 'login_success')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? AppTranslations.translate(context, 'error'),
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } catch (e) {
      print('Login error: $e');
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Erreur réseau: Vérifiez votre connexion au serveur',
          ),
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
                      AppTranslations.translate(context, 'welcome_back'),
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
                            AppTranslations.translate(context, 'sign_in'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
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
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
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
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
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
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              ),
                              child: Text(
                                AppTranslations.translate(
                                  context,
                                  'forgot_password',
                                ),
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 23, 95, 114),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
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
                                        'sign_in',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
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
                            'dont_have_account',
                          ),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            '/register',
                          ),
                          child: Text(
                            ' ${AppTranslations.translate(context, 'sign_up')}',
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
    );
  }
}

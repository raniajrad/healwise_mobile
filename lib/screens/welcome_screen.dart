import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/language_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();

    LanguageService.onLocaleChanged = () {
      setState(() {});
    };
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LanguageService.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background subtle pattern
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPatternPainter(),
              size: Size.infinite,
            ),
          ),
          // Language selector
          Positioned(
            top: 50,
            right: isRTL ? null : 24,
            left: isRTL ? 24 : null,
            child: _buildLanguageSelector(),
          ),
          // Main content
          SafeArea(
            child: Directionality(
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Logo avec animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(
                                    255,
                                    45,
                                    54,
                                    230,
                                  ).withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: const Color.fromARGB(
                                    255,
                                    39,
                                    43,
                                    244,
                                  ).withValues(alpha: 0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/logo.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color.fromARGB(255, 23, 95, 114),
                                          Color.fromARGB(255, 23, 95, 114),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.health_and_safety,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 23, 95, 114),
                                Color.fromARGB(255, 23, 95, 114),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'HealWise',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getSubtitle(),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          _buildButton(
                            text: _getRegisterText(),
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            isPrimary: true,
                          ),
                          const SizedBox(height: 12),
                          _buildButton(
                            text: _getLoginText(),
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            isPrimary: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption('en', 'EN'),
          _buildLanguageOption('fr', 'FR'),
          _buildLanguageOption('ar', 'AR'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String langCode, String label) {
    final isSelected = LanguageService.locale.languageCode == langCode;
    return GestureDetector(
      onTap: () {
        LanguageService.setLocale(langCode);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 23, 95, 114),
                    Color.fromARGB(255, 23, 95, 114),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isPrimary
            ? const LinearGradient(
                colors: [
                  Color.fromARGB(255, 23, 95, 114),
                  Color.fromARGB(255, 23, 95, 114),
                ],
              )
            : null,
        color: isPrimary ? null : Colors.grey[50],
        border: isPrimary
            ? null
            : Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Color.fromARGB(255, 23, 95, 114),

                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : Colors.grey[800],
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (LanguageService.locale.languageCode) {
      case 'fr':
        return 'Votre compagnon santé intelligent';
      case 'ar':
        return 'رفيقك الصحي الذكي';
      default:
        return 'Your smart health companion';
    }
  }

  String _getRegisterText() {
    switch (LanguageService.locale.languageCode) {
      case 'fr':
        return 'Créer un compte';
      case 'ar':
        return 'إنشاء حساب';
      default:
        return 'Create account';
    }
  }

  String _getLoginText() {
    switch (LanguageService.locale.languageCode) {
      case 'fr':
        return 'Se connecter';
      case 'ar':
        return 'تسجيل الدخول';
      default:
        return 'Log in';
    }
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final math.Random _random = math.Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 10, 96, 142).withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw subtle grid pattern
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw some soft circles
    final circlePaint = Paint()
      ..color = const Color.fromARGB(255, 4, 74, 117).withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      double x = _random.nextDouble() * size.width;
      double y = _random.nextDouble() * size.height;
      double radius = 50 + _random.nextDouble() * 100;
      canvas.drawCircle(Offset(x, y), radius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

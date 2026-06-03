import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/language_service.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final AnimationController _animationController;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _animationController.forward();
    _slideController.forward();

    LanguageService.onLocaleChanged = () {
      setState(() {});
    };
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String get _selectedLanguage => LanguageService.locale.languageCode;

  void _changeLanguage(String langCode) {
    LanguageService.setLocale(langCode);
    if (langCode == 'ar') {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
      );
    }
    setState(() {});
  }

  List<OnboardingPageData> get _pages {
    switch (_selectedLanguage) {
      case 'fr':
        return [
          OnboardingPageData(
            icon: Icons.monitor_heart_outlined,
            title: 'Surveillance Intelligente',
            description:
                'Suivez vos indicateurs de santé en temps réel grâce à l\'intelligence artificielle.',
          ),
          OnboardingPageData(
            icon: Icons.shield_outlined,
            title: 'Prévention Proactive',
            description:
                'Anticipez les risques avec nos algorithmes prédictifs avancés.',
          ),
          OnboardingPageData(
            icon: Icons.device_hub_outlined,
            title: 'Écosystème Connecté',
            description:
                'Restez en contact avec vos professionnels de santé préférés.',
          ),
        ];
      case 'ar':
        return [
          OnboardingPageData(
            icon: Icons.monitor_heart_outlined,
            title: 'مراقبة ذكية للصحة',
            description:
                'تابع مؤشراتك الصحية في الوقت الفعلي باستخدام الذكاء الاصطناعي',
          ),
          OnboardingPageData(
            icon: Icons.shield_outlined,
            title: 'وقاية استباقية',
            description: 'توقع المخاطر الصحية مع خوارزميات التنبؤ المتقدمة',
          ),
          OnboardingPageData(
            icon: Icons.device_hub_outlined,
            title: 'نظام صحي متكامل',
            description:
                'ابق على اتصال مع أخصائيي الرعاية الصحية المفضلين لديك',
          ),
        ];
      default:
        return [
          OnboardingPageData(
            icon: Icons.monitor_heart_outlined,
            title: 'Smart Monitoring',
            description:
                'Track your health metrics in real-time with AI-powered insights.',
          ),
          OnboardingPageData(
            icon: Icons.shield_outlined,
            title: 'Proactive Prevention',
            description:
                'Stay ahead of risks with advanced predictive algorithms.',
          ),
          OnboardingPageData(
            icon: Icons.device_hub_outlined,
            title: 'Connected Care',
            description:
                'Stay connected with your preferred healthcare professionals.',
          ),
        ];
    }
  }

  String get _skipText {
    switch (_selectedLanguage) {
      case 'fr':
        return 'Passer';
      case 'ar':
        return 'تخطي';
      default:
        return 'Skip';
    }
  }

  String get _nextText {
    switch (_selectedLanguage) {
      case 'fr':
        return 'Suivant';
      case 'ar':
        return 'التالي';
      default:
        return 'Next';
    }
  }

  String get _getStartedText {
    switch (_selectedLanguage) {
      case 'fr':
        return 'Commencer';
      case 'ar':
        return 'ابدأ';
      default:
        return 'Get Started';
    }
  }

  bool get _isRTL => _selectedLanguage == 'ar';

  void _onSkip() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const WelcomePage()));
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _onGetStarted();
    }
  }

  void _onGetStarted() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const WelcomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            children: [
              // Header avec sélecteur de langue et skip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLanguageSelector(),
                    TextButton(
                      onPressed: _onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                      child: Text(
                        _skipText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _animationController.reset();
                    _animationController.forward();
                  },
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Bottom controls
              _buildBottomControls(),
            ],
          ),
        ),
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
    final isSelected = _selectedLanguage == langCode;
    return GestureDetector(
      onTap: () => _changeLanguage(langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 23, 95, 114)
              : Colors.transparent,
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

  Widget _buildPage(OnboardingPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon avec animation
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.9 + (_animationController.value * 0.1),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 23, 95, 114),
                        Color.fromARGB(255, 23, 95, 114),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromARGB(255, 23, 95, 114),

                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(page.icon, size: 50, color: Colors.white),
                ),
              );
            },
          ),

          const SizedBox(height: 48),

          // Titre
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1F3A),
              height: 1.3,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.6,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  gradient: _currentPage == index
                      ? const LinearGradient(
                          colors: [
                            const Color.fromARGB(255, 23, 95, 114),
                            const Color.fromARGB(255, 23, 95, 114),
                          ],
                        )
                      : null,
                  color: _currentPage == index ? null : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Next/Get Started button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 23, 95, 114),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? _getStartedText : _nextText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

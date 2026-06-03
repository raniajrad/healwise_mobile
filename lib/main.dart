import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/manual_entry_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/analytics_screen.dart';

import 'services/language_service.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'config/theme_config.dart';
import 'config/api_config.dart';
import 'package:logger/logger.dart';

// Test API function
Future<void> testApi() async {
  var url = Uri.parse(ApiConfig.baseUrl + '/test');

  try {
    var response = await http
        .get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      debugPrint(data["message"]);
    } else {
      debugPrint("Error: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("API Test Failed: $e");
  }
}

final GlobalKey<_HealWiseAppState> _appKey = GlobalKey<_HealWiseAppState>();

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  logger.i("Application commencé");

  await LanguageService.init();
  await ThemeService.init();
  await NotificationService.init();

  runApp(HealWiseApp(key: _appKey));
}

class HealWiseApp extends StatefulWidget {
  const HealWiseApp({super.key});

  @override
  State<HealWiseApp> createState() => _HealWiseAppState();
}

class _HealWiseAppState extends State<HealWiseApp> {
  @override
  void initState() {
    super.initState();
    // Listen to language changes - force complete rebuild
    LanguageService.onLocaleChanged = () {
      setState(() {});
    };
    // Listen to theme changes
    ThemeService.themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    LanguageService.onLocaleChanged = null;
    ThemeService.themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealWise',
      locale: LanguageService.locale,
      supportedLocales: LanguageService.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeService.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/onboarding': (context) => const WelcomePage(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomeScreen(),
        '/manual-entry': (context) => const ManualEntryScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
      },
    );
  }
}

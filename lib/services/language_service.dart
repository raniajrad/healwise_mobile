import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';

  static Locale _locale = const Locale('en');

  // Callback for locale changes - make it static and not nullable for easier use
  static void Function()? onLocaleChanged;

  static Locale get locale => _locale;

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  // Language names
  static const Map<String, String> languageNames = {
    'en': 'English',
    'fr': 'Français',
    'ar': 'العربية',
  };

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    _locale = Locale(languageCode);
  }

  static Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    // Notify listeners about the change - directly call the callback
    if (onLocaleChanged != null) {
      onLocaleChanged!();
    }
  }

  static String getLanguageName(String code) {
    return languageNames[code] ?? 'English';
  }

  static bool isRTL(String code) {
    return code == 'ar';
  }
}

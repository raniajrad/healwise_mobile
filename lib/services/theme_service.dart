import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  static late SharedPreferences _prefs;

  static bool _isDarkMode = false;
  static final ValueNotifier<bool> _themeNotifier = ValueNotifier<bool>(
    _isDarkMode,
  );

  static ValueNotifier<bool> get themeNotifier => _themeNotifier;
  static bool get isDarkMode => _isDarkMode;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    _themeNotifier.value = _isDarkMode;
  }

  static Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    _themeNotifier.value = _isDarkMode;
    await _prefs.setBool(_themeKey, isDark);
  }

  static Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }

  static ThemeMode getThemeMode() {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}

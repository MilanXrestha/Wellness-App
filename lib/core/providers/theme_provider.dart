import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../resources/app_themes.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themeKey = 'theme_mode';

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData getTheme() {
    return _isDarkMode ? AppTheme.darkTheme() : AppTheme.lightTheme();
  }
}
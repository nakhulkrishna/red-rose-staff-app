import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = "theme_mode";
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider();

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> loadThemeFromPrefs() async {  // <-- public
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_themeKey, _themeMode.index);
  }
}

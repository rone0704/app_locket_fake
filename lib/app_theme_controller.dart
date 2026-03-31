import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController {
  static const String _themeModeKey = 'theme_mode';

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeModeKey) ?? 'system';
    themeMode.value = _fromRaw(raw);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode.value != mode) {
      themeMode.value = mode;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _toRaw(mode));
  }

  static String labelOf(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Sang';
      case ThemeMode.dark:
        return 'Toi';
      case ThemeMode.system:
        return 'Tu dong';
    }
  }

  static ThemeMode _fromRaw(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toRaw(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DarkPalette {
  midnight,
  deepSea,
  spaceGray,
  amethyst,
  obsidianGreen,
  carbonRed,
  arcticDark,
  nebulaBrown,
}

class AppThemeController {
  static const String _themeModeKey = 'theme_mode';
  static const String _darkPaletteKey = 'dark_palette';

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);
  static final ValueNotifier<DarkPalette> darkPalette =
      ValueNotifier<DarkPalette>(DarkPalette.midnight);

  static Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeRaw = prefs.getString(_themeModeKey) ?? 'system';
    final paletteRaw = prefs.getString(_darkPaletteKey) ?? 'midnight';
    themeMode.value = _fromRaw(modeRaw);
    darkPalette.value = _paletteFromRaw(paletteRaw);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode.value != mode) {
      themeMode.value = mode;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _toRaw(mode));
  }

  static Future<void> setDarkPalette(DarkPalette palette) async {
    if (darkPalette.value != palette) {
      darkPalette.value = palette;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_darkPaletteKey, _paletteToRaw(palette));
  }

  static String labelOf(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.dark:
        return 'Tối';
      case ThemeMode.system:
        return 'Tự động';
    }
  }

  static String labelOfPalette(DarkPalette palette) {
    switch (palette) {
      case DarkPalette.midnight:
        return 'Midnight';
      case DarkPalette.deepSea:
        return 'Deep Sea';
      case DarkPalette.spaceGray:
        return 'Space Gray';
      case DarkPalette.amethyst:
        return 'Amethyst';
      case DarkPalette.obsidianGreen:
        return 'Obsidian Green';
      case DarkPalette.carbonRed:
        return 'Carbon Red';
      case DarkPalette.arcticDark:
        return 'Arctic Dark';
      case DarkPalette.nebulaBrown:
        return 'Nebula Brown';
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

  static DarkPalette _paletteFromRaw(String raw) {
    switch (raw) {
      case 'deep_sea':
        return DarkPalette.deepSea;
      case 'space_gray':
        return DarkPalette.spaceGray;
      case 'amethyst':
        return DarkPalette.amethyst;
      case 'obsidian_green':
        return DarkPalette.obsidianGreen;
      case 'carbon_red':
        return DarkPalette.carbonRed;
      case 'arctic_dark':
        return DarkPalette.arcticDark;
      case 'nebula_brown':
        return DarkPalette.nebulaBrown;
      default:
        return DarkPalette.midnight;
    }
  }

  static String _paletteToRaw(DarkPalette palette) {
    switch (palette) {
      case DarkPalette.midnight:
        return 'midnight';
      case DarkPalette.deepSea:
        return 'deep_sea';
      case DarkPalette.spaceGray:
        return 'space_gray';
      case DarkPalette.amethyst:
        return 'amethyst';
      case DarkPalette.obsidianGreen:
        return 'obsidian_green';
      case DarkPalette.carbonRed:
        return 'carbon_red';
      case DarkPalette.arcticDark:
        return 'arctic_dark';
      case DarkPalette.nebulaBrown:
        return 'nebula_brown';
    }
  }
}

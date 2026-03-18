import 'package:flutter/material.dart';

// ==========================================
// APP THEME & STYLES
// ==========================================

class AppTheme {
  // Colors
  static const Color primaryColor = Colors.black;
  static const Color accentColor = Colors.amber;
  static const Color errorColor = Colors.redAccent;
  static const Color successColor = Color(0xFF4CAF50);
  
  static Color get darkGrey => Colors.grey[900]!;
  static Color get mediumGrey => Colors.grey[800]!;
  static Color get lightGrey => Colors.grey[700]!;

  // Border Radius
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 20;

  // Padding & Spacing
  static const double spacingXSmall = 4;
  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;
  static const double spacingXLarge = 32;

  // Text Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: Colors.white,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: Colors.white70,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: Colors.white54,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Input Decoration
  static InputDecoration getInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool isError = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.grey[900],
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.amber)
          : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(
          color: isError ? Colors.red : Colors.grey.shade700,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(
          color: isError ? Colors.red : Colors.grey.shade700,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(
          color: isError ? Colors.red : Colors.amber,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMedium,
        vertical: spacingSmall,
      ),
    );
  }

  // Button Styles
  static ElevatedButtonThemeData get elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLarge,
          vertical: spacingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    );
  }

  // Box Shadows
  static List<BoxShadow> get boxShadow {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> get boxShadowSmall {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  // Gradients
  static Gradient get amberGradient {
    return const LinearGradient(
      colors: [Colors.amber, Color(0xFFFFB74D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Gradient get darkGradient {
    return LinearGradient(
      colors: [Colors.grey[900]!, Colors.grey[800]!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// ==========================================
// THEME DATA
// ==========================================

ThemeData getAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppTheme.primaryColor,
    scaffoldBackgroundColor: AppTheme.primaryColor,
    appBarTheme: AppBarTheme(
      backgroundColor: AppTheme.darkGrey,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTheme.titleMedium,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.darkGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: AppTheme.primaryColor,
      secondary: AppTheme.accentColor,
      error: AppTheme.errorColor,
      surface: AppTheme.darkGrey,
    ),
  );
}

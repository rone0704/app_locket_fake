import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme_controller.dart';

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

class _FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.02, 0.015),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

ThemeData _buildTheme(
  Brightness brightness, [
  DarkPalette darkPalette = DarkPalette.midnight,
]) {
  final isDark = brightness == Brightness.dark;
  final palette = _resolvePalette(isDark ? darkPalette : DarkPalette.midnight);
  final scaffold = isDark ? palette.scaffold : const Color(0xFFF8F7F3);
  final surface = isDark ? palette.surface : Colors.white;
  final text = isDark ? Colors.white : const Color(0xFF181A1F);
  final muted = isDark ? palette.muted : const Color(0xFF646B78);

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: scaffold,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFF6AA1C),
      brightness: brightness,
      primary: const Color(0xFFF6AA1C),
      surface: surface,
      error: const Color(0xFFE04545),
    ),
  );

  final textTheme = GoogleFonts.nunitoSansTextTheme(base.textTheme).copyWith(
    titleLarge: GoogleFonts.nunitoSans(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: text,
      letterSpacing: -0.35,
    ),
    titleMedium: GoogleFonts.nunitoSans(
      fontSize: 21,
      fontWeight: FontWeight.w800,
      color: text,
    ),
    bodyLarge: GoogleFonts.nunitoSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: text,
    ),
    bodyMedium: GoogleFonts.nunitoSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: muted,
    ),
    labelLarge: GoogleFonts.nunitoSans(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: text,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: text,
      titleTextStyle: textTheme.titleMedium,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
        TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
        TargetPlatform.linux: _FadeSlidePageTransitionsBuilder(),
        TargetPlatform.macOS: _FadeSlidePageTransitionsBuilder(),
        TargetPlatform.windows: _FadeSlidePageTransitionsBuilder(),
      },
    ),
    iconTheme: IconThemeData(
      color: isDark ? Colors.white : const Color(0xFF22252B),
      size: 22,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1C2128) : const Color(0xFFF1F3F6),
      hintStyle: TextStyle(
        color: isDark ? Colors.white54 : const Color(0xFF999999),
        fontSize: 14,
      ),
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : const Color(0xFF555555),
      ),
      prefixStyle: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF181A1F),
      ),
      suffixStyle: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF181A1F),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2A3039) : const Color(0xFFD7DDE5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF6AA1C), width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class _DarkPaletteScheme {
  final Color scaffold;
  final Color surface;
  final Color input;
  final Color border;
  final Color muted;

  const _DarkPaletteScheme({
    required this.scaffold,
    required this.surface,
    required this.input,
    required this.border,
    required this.muted,
  });
}

_DarkPaletteScheme _resolvePalette(DarkPalette palette) {
  switch (palette) {
    case DarkPalette.obsidianGreen:
      return const _DarkPaletteScheme(
        scaffold: Color(0xFF08120C),
        surface: Color(0xFF101D16),
        input: Color(0xFF16291F),
        border: Color(0xFF274033),
        muted: Color(0xFFC2D4C7),
      );
    case DarkPalette.carbonRed:
      return const _DarkPaletteScheme(
        scaffold: Color(0xFF13090A),
        surface: Color(0xFF221214),
        input: Color(0xFF2A181B),
        border: Color(0xFF4A2B30),
        muted: Color(0xFFD8C0C2),
      );
    case DarkPalette.arcticDark:
      return const _DarkPaletteScheme(
        scaffold: Color(0xFF0B1016),
        surface: Color(0xFF151D27),
        input: Color(0xFF1C2632),
        border: Color(0xFF2D3C4E),
        muted: Color(0xFFC4D2E0),
      );
    case DarkPalette.nebulaBrown:
      return const _DarkPaletteScheme(
        scaffold: Color(0xFF120F0C),
        surface: Color(0xFF201A15),
        input: Color(0xFF2A221C),
        border: Color(0xFF47392E),
        muted: Color(0xFFD3C5B7),
      );
    case DarkPalette.deepSea:
      return const _DarkPaletteScheme(
        scaffold: Color(0xFF07121D),
        surface: Color(0xFF0E1D2B),
        input: Color(0xFF132535),
        border: Color(0xFF1F3346),
        muted: Color(0xFFB1C0D2),
      );
    case DarkPalette.spaceGray:
      return const _DarkPaletteScheme(
        scaffold: Color(0xFF121317),
        surface: Color(0xFF1B1D23),
        input: Color(0xFF23262D),
        border: Color(0xFF31353D),
        muted: Color(0xFFC0C4CC),
      );
    case DarkPalette.amethyst:
      return const _DarkPaletteScheme(
        scaffold: Color(0xFF120D18),
        surface: Color(0xFF1D1528),
        input: Color(0xFF261D33),
        border: Color(0xFF3A2C4B),
        muted: Color(0xFFD0C3E3),
      );
    case DarkPalette.midnight:
      return const _DarkPaletteScheme(
        scaffold: Color(0xFF070809),
        surface: Color(0xFF121418),
        input: Color(0xFF1A1D22),
        border: Color(0xFF2A2E35),
        muted: Color(0xFFC1C6CF),
      );
  }
}

ThemeData getLightTheme() => _buildTheme(Brightness.light);

ThemeData getDarkTheme([DarkPalette palette = DarkPalette.midnight]) {
  final scheme = _resolvePalette(palette);
  final theme = _buildTheme(Brightness.dark, palette);
  return theme.copyWith(
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      fillColor: scheme.input,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF6AA1C), width: 2),
      ),
    ),
  );
}

ThemeData getAppTheme() {
  return getDarkTheme();
}

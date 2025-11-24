import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandColors {
  // Updated colors from user's palette image
  static const Color jacaranda = Color(0xFF30012F); // Dark purple
  static const Color cardinalPink = Color(0xFF7E0562); // Magenta pink
  static const Color persianRed = Color(0xFFC92F2D); // Red-orange
  static const Color ecstasy = Color(0xFFF9751E); // Orange
  static const Color alabaster = Color(0xFFFCFCFC); // Light neutral
  static const Color codGrey = Color(0xFF121212); // Dark neutral

  // Additional gradient colors for modern design
  static const Color primaryGradientStart = jacaranda;
  static const Color primaryGradientEnd = cardinalPink;
  static const Color accentGradientStart = persianRed;
  static const Color accentGradientEnd = ecstasy;
  
  // Accent colors for better UI
  static const Color goldAccent = Color(0xFFFFD85E);
  static const Color purpleLight = Color(0xFF9B4D96);
  static const Color orangeLight = Color(0xFFFFB84D);
}

class BrandTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: BrandColors.jacaranda,
      brightness: Brightness.light,
      primary: BrandColors.jacaranda,
      secondary: BrandColors.cardinalPink,
      tertiary: BrandColors.ecstasy,
      surface: BrandColors.alabaster,
      onPrimary: BrandColors.alabaster,
      onSecondary: BrandColors.alabaster,
      onTertiary: BrandColors.codGrey,
      onSurface: BrandColors.codGrey,
      error: BrandColors.persianRed,
      onError: BrandColors.alabaster,
    );
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme);
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme.apply(
        displayColor: BrandColors.codGrey,
        bodyColor: BrandColors.codGrey,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: BrandColors.codGrey,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              24,
            ), // More rounded for unique feel
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          elevation: 4, // Added shadow for depth
          shadowColor: colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.tertiary,
          textStyle: textTheme.titleMedium,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: BrandColors.jacaranda,
      brightness: Brightness.dark,
      primary: BrandColors.jacaranda,
      secondary: BrandColors.cardinalPink,
      tertiary: BrandColors.ecstasy,
      surface: BrandColors.codGrey,
      onPrimary: BrandColors.alabaster,
      onSecondary: BrandColors.alabaster,
      onTertiary: BrandColors.codGrey,
      onSurface: BrandColors.alabaster,
      error: BrandColors.persianRed,
      onError: BrandColors.alabaster,
    );
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme);
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme
          .apply(
            displayColor: BrandColors.alabaster,
            bodyColor: BrandColors.alabaster,
          )
          .copyWith(
            headlineLarge: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            headlineMedium: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.25,
            ),
            titleLarge: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.6),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: BrandColors.alabaster,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: textTheme.titleMedium,
        ),
      ),
    );
  }
}

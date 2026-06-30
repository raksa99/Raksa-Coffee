import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Palette (Warm Sand & Pearl)
  static const Color lightBg = Color(0xFFFAF8F5); // Pearl sand background
  static const Color lightCard = Colors.white;
  static const Color lightSurface = Color(0xFFF4EFEA); // Soft sand surface
  static const Color lightBorder = Color(0xFFE8DFD5); // Delicate warm border
  static const Color lightTextPrimary = Color(0xFF1F1511); // Deep charcoal cocoa
  static const Color lightTextSecondary = Color(0xFF6E5E57); // Medium sand cocoa
  
  // Dark Theme Palette (Obsidian Espresso)
  static const Color darkBg = Color(0xFF0B0909); // Obsidian background
  static const Color darkCard = Color(0xFF151211); // Deep warm card
  static const Color darkSurface = Color(0xFF1D1918); // Warm dark surface
  static const Color darkBorder = Color(0xFF2A2321); // Dark cocoa border
  static const Color darkTextPrimary = Color(0xFFF5F0EC); // Cream white text
  static const Color darkTextSecondary = Color(0xFFA3958F); // Soft cream cocoa text

  // Common Brand Colors
  static const Color primary = Color(0xFF9A6655); // Premium warm bronze
  static const Color primaryLight = Color(0xFFB57F6D);
  static const Color accent = Color(0xFFD09865); // Roasted Gold
  static const Color accentLight = Color(0xFFE5B588);
  
  static const Color success = Color(0xFF4A7C59); // Sage Green
  static const Color warning = Color(0xFFD3A24B); // Amber
  static const Color danger = Color(0xFFB84A39); // Rust Red
  static const Color info = Color(0xFF537A9B); // Slate Blue
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightBorder,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightCard,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: AppColors.lightTextPrimary,
        onSurface: AppColors.lightTextPrimary,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary, fontFamily: 'Outfit'),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary, fontFamily: 'Outfit'),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary, fontFamily: 'Outfit'),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary, fontFamily: 'Outfit'),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.lightTextPrimary, fontFamily: 'Outfit'),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.lightTextSecondary, fontFamily: 'Outfit'),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary, fontFamily: 'Outfit'),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightCard,
        elevation: 20,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: const StadiumBorder(),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary.withAlpha(40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.accent,
        surface: AppColors.darkCard,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: AppColors.darkTextPrimary,
        onSurface: AppColors.darkTextPrimary,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary, fontFamily: 'Outfit'),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary, fontFamily: 'Outfit'),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary, fontFamily: 'Outfit'),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary, fontFamily: 'Outfit'),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.darkTextPrimary, fontFamily: 'Outfit'),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkTextSecondary, fontFamily: 'Outfit'),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary, fontFamily: 'Outfit'),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        elevation: 20,
        shadowColor: Colors.black.withAlpha(80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: const StadiumBorder(),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: AppColors.primaryLight.withAlpha(30),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          side: const BorderSide(color: AppColors.darkBorder, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

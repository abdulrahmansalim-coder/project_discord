import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette — deep midnight with electric accents
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color accent = Color(0xFF00D4AA);
  static const Color accentWarm = Color(0xFFFF6B6B);

  // Dark colors
  static const Color bgDark = Color(0xFF0D0E1A);
  static const Color bgCard = Color(0xFF171829);
  static const Color bgInput = Color(0xFF1E2035);
  static const Color bgBubbleSelf = Color(0xFF6C63FF);
  static const Color bgBubbleOther = Color(0xFF1E2035);

  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8A8BA8);
  static const Color textMuted = Color(0xFF4A4B65);
  static const Color divider = Color(0xFF1E2035);

  // Light colors
  static const Color bgLight = Color(0xFFF5F5FF);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgInputLight = Color(0xFFEEEEFF);
  static const Color bgBubbleOtherLight = Color(0xFFEEEEFF);

  static const Color textPrimaryLight = Color(0xFF0D0E1A);
  static const Color textSecondaryLight = Color(0xFF555570);
  static const Color textMutedLight = Color(0xFFAAAAAA);
  static const Color dividerLight = Color(0xFFE0E0F0);

  static const Color online = Color(0xFF00D4AA);
  static const Color away = Color(0xFFFFB347);
  static const Color offline = Color(0xFF4A4B65);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: bgCard,
        background: bgDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      fontFamily: 'Nunito',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Nunito',
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        labelSmall: TextStyle(color: textMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: bgCardLight,
        background: bgLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        onBackground: textPrimaryLight,
      ),
      fontFamily: 'Nunito',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Nunito',
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: textPrimaryLight),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: textPrimaryLight),
        bodyMedium: TextStyle(color: textSecondaryLight),
        labelSmall: TextStyle(color: textMutedLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgInputLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textMutedLight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCardLight,
        selectedItemColor: primary,
        unselectedItemColor: textMutedLight,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
      ),
    );
  }
}
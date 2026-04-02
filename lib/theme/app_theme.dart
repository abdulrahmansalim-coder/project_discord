import 'package:flutter/material.dart';

class AppTheme {
  // ── Dark palette ────────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF6C63FF);
  static const Color primaryLight   = Color(0xFF9D97FF);
  static const Color accent         = Color(0xFF00D4AA);
  static const Color accentWarm     = Color(0xFFFF6B6B);

  static const Color bgDark         = Color(0xFF0D0E1A);
  static const Color bgCard         = Color(0xFF171829);
  static const Color bgInput        = Color(0xFF1E2035);
  static const Color bgBubbleSelf   = Color(0xFF6C63FF);
  static const Color bgBubbleOther  = Color(0xFF1E2035);

  static const Color textPrimary    = Color(0xFFF0F0FF);
  static const Color textSecondary  = Color(0xFF8A8BA8);
  static const Color textMuted      = Color(0xFF4A4B65);
  static const Color divider        = Color(0xFF1E2035);

  static const Color online         = Color(0xFF00D4AA);
  static const Color away           = Color(0xFFFFB347);
  static const Color offline        = Color(0xFF4A4B65);

  // ── Light palette ───────────────────────────────────────────────────────────
  static const Color bgLight            = Color(0xFFF5F6FA);
  static const Color bgCardLight        = Color(0xFFFFFFFF);
  static const Color bgInputLight       = Color(0xFFEEEFF5);
  static const Color bgBubbleSelfLight  = Color(0xFF6C63FF);
  static const Color bgBubbleOtherLight = Color(0xFFEEEFF5);

  static const Color textPrimaryLight   = Color(0xFF0D0E1A);
  static const Color textSecondaryLight = Color(0xFF4A4B65);
  static const Color textMutedLight     = Color(0xFF9A9BB5);
  static const Color dividerLight       = Color(0xFFE4E5F0);

  // ── Dark Theme ──────────────────────────────────────────────────────────────
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
      dividerColor: divider,
      cardColor: bgCard,
    );
  }

  // ── Light Theme ─────────────────────────────────────────────────────────────
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
      dividerColor: dividerLight,
      cardColor: bgCardLight,
    );
  }
}

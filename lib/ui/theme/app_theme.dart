import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  // Define color palette
  static const Color _primary = Color(0xFF4CAF50); // A green shade, suitable for agriculture theme
  static const Color _primaryDark = Color(0xFF388E3C);
  static const Color _primaryLight =
      Color(0xFFC8E6C9);
  static const Color _accent = Color(0xFFFF9800); // An orange accent
  static const Color _textPrimary = Color(0xFF212121);
  static const Color _textSecondary = Color(0xFF757575);
  static const Color _background = Color(0xFFFFFFFF);
  static const Color _divider = Color(0xFFBDBDBD);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: _primary,
      primaryColorDark: _primaryDark,
      primaryColorLight: _primaryLight,
      scaffoldBackgroundColor: _background,
      appBarTheme: const AppBarTheme(
        color: _primary,
        elevation: 4.0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: _primary,
        secondary: _accent,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        surface: _background,
        onSurface: _textPrimary,
        error: Colors.red,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 32.0, fontWeight: FontWeight.bold, color: _textPrimary),
        headlineMedium: TextStyle(
            fontSize: 24.0, fontWeight: FontWeight.bold, color: _textPrimary),
        headlineSmall: TextStyle(
            fontSize: 20.0, fontWeight: FontWeight.w600, color: _textPrimary),
        bodyLarge: TextStyle(fontSize: 16.0, color: _textPrimary),
        bodyMedium: TextStyle(fontSize: 14.0, color: _textSecondary),
        labelLarge: TextStyle(
            fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      dividerColor: _divider,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: _primary, width: 2.0),
        ),
        labelStyle: const TextStyle(color: _textSecondary),
      ),
    );
  }
}

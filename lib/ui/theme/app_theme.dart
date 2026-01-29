import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // Private constructor

  // --- 1. กำหนด Palette สีใหม่ (Earth Tone / Brown) ---
  static const Color _primary = Color(0xFF5D4037); // Brown 700 (สีหลัก)
  static const Color _primaryLight =
      Color(0xFF8D6E63); // Brown 400 (สีรอง/Accent)
  static const Color _primaryDark = Color(0xFF3E2723); // Brown 900
  static const Color _background = Color(0xFFEFEBE9); // Brown 50 (สีพื้นหลัง)
  static const Color _surface = Colors.white; // สีพื้น Card/Dialog

  static const Color _textPrimary =
      Color(0xFF3E2723); // ข้อความหลัก (น้ำตาลเข้มเกือบดำ)
  static const Color _textSecondary =
      Color(0xFF6D4C41); // ข้อความรอง (น้ำตาลกลาง)
  static const Color _divider = Color(0xFFA1887F); // เส้นคั่น (Brown 300)

  static ThemeData get lightTheme {
    return ThemeData(
      // --- Core Color Scheme ---
      primaryColor: _primary,
      primaryColorDark: _primaryDark,
      primaryColorLight: _primaryLight,
      scaffoldBackgroundColor: _background, // พื้นหลังแอปเป็นสีครีม

      colorScheme: const ColorScheme.light(
        primary: _primary,
        secondary: _primaryLight, // ใช้สีน้ำตาลอ่อนเป็น Secondary
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        surface: _surface,
        onSurface: _textPrimary,
        error: Color(0xFFB00020),
        onError: Colors.white,
      ),

      // --- AppBar Theme ---
      appBarTheme: const AppBarTheme(
        backgroundColor: _primary,
        foregroundColor: Colors.white, // สีไอคอนและข้อความ
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),

      // --- Typography ---
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 32.0, fontWeight: FontWeight.bold, color: _primaryDark),
        headlineMedium: TextStyle(
            fontSize: 24.0, fontWeight: FontWeight.bold, color: _primary),
        headlineSmall: TextStyle(
            fontSize: 20.0, fontWeight: FontWeight.bold, color: _primary),
        titleLarge: TextStyle(
            fontSize: 18.0, fontWeight: FontWeight.w600, color: _textPrimary),
        bodyLarge: TextStyle(fontSize: 16.0, color: _textPrimary),
        bodyMedium: TextStyle(fontSize: 14.0, color: _textSecondary),
        labelLarge: TextStyle(
          fontSize: 16.0, fontWeight: FontWeight.bold, color: _textPrimary),
      ),

      dividerColor: _divider,

      // --- Card Theme ---
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 2,
        shadowColor: _primary.withValues(alpha: 0.2),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),

      // --- Button Styles ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        ),
      ),

      // --- Input/Form Theme ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: _primary, width: 2.0),
        ),
        labelStyle: const TextStyle(color: _textSecondary),
        floatingLabelStyle: const TextStyle(color: _primary),
      ),

      // --- Floating Action Button ---
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: _textPrimary,
        unselectedLabelColor: _textSecondary.withOpacity(0.8),
        indicatorColor: _primary,
      ),
    );
  }
}

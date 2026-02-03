import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  AppTheme._(); // Private constructor

  // --- Wizard Colors (Earth Tones) ---
  static const Color _primary = Color(0xFF795548); // Brown 500
  static const Color _primaryLight = Color(0xFFD7CCC8); // Brown 100
  static const Color _primaryDark = Color(0xFF3E2723); // Brown 900
  static const Color _background = Color(0xFFF5F5F5); // Light Gray/White
  static const Color _surface = Colors.white;
  static const Color _textPrimary = Color(0xFF3E2723); // Dark Brown
  static const Color _textSecondary = Color(0xFF8D6E63); // Light Brown
  static const Color _divider = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // --- Core Color Scheme ---
      primaryColor: _primary,
      primaryColorDark: _primaryDark,
      primaryColorLight: _primaryLight,
      scaffoldBackgroundColor: _background,

      colorScheme: const ColorScheme.light(
        primary: _primary,
        secondary: _primaryLight,
        onPrimary: Colors.white,
        onSecondary: _textPrimary,
        surface: _surface,
        onSurface: _textPrimary,
        error: Color(0xFFB00020),
        onError: Colors.white,
      ),

      // --- AppBar Theme ---
      appBarTheme: AppBarTheme(
        backgroundColor: _background, // Clean look: background color
        foregroundColor: _textPrimary, // Dark text
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _textPrimary),
        titleTextStyle: GoogleFonts.prompt(
          color: _textPrimary,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),

      // --- Typography ---
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.prompt(
            fontSize: 28.sp, fontWeight: FontWeight.bold, color: _primaryDark),
        headlineMedium: GoogleFonts.prompt(
            fontSize: 24.sp, fontWeight: FontWeight.bold, color: _primary),
        headlineSmall: GoogleFonts.prompt(
            fontSize: 20.sp, fontWeight: FontWeight.bold, color: _textPrimary),
        titleLarge: GoogleFonts.prompt(
            fontSize: 20.sp, fontWeight: FontWeight.w600, color: _textPrimary),
        titleMedium: GoogleFonts.prompt(
            fontSize: 16.sp, fontWeight: FontWeight.w600, color: _textPrimary),
        bodyLarge: GoogleFonts.prompt(fontSize: 16.sp, color: _textPrimary),
        bodyMedium: GoogleFonts.prompt(fontSize: 14.sp, color: _textSecondary),
        labelLarge: GoogleFonts.prompt(
            fontSize: 16.sp, fontWeight: FontWeight.bold, color: _textPrimary),
      ),

      dividerColor: _divider,

      // --- Card Theme ---
      cardTheme: CardThemeData(
        color: _surface,
        elevation:
            0, // Flat with shadow handled by decoration mostly, but let's give it a slight elevation default
        margin: EdgeInsets.only(bottom: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r), // Standardize to 24
        ),
      ),

      // --- Button Styles ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r), // Pill shape
          ),
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
          textStyle: GoogleFonts.prompt(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
          ),
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
          textStyle: GoogleFonts.prompt(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _textSecondary,
          textStyle: GoogleFonts.prompt(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // --- Input/Form Theme ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: _primary, width: 2.0),
        ),
        labelStyle: TextStyle(color: _textSecondary, fontSize: 14.sp),
        floatingLabelStyle: TextStyle(color: _primary, fontSize: 14.sp),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
      ),

      // --- Floating Action Button ---
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(), // Or rounded rect if preferred
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: _primary,
        unselectedLabelColor: _textSecondary,
        indicatorColor: _primary,
        labelStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.prompt(),
      ),

      // --- Bottom Navigation Bar ---
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _primary,
        unselectedItemColor: _textSecondary,
        selectedLabelStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.prompt(),
      ),
    );
  }
}

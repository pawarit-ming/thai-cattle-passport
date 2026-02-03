import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class WizardColors {
  // Earth tones from the mockup
  static const Color primarySpring = Color(0xFF795548); // Brownish
  static const Color secondarySpring = Color(0xFFD7CCC8); // Light Brown
  static const Color background = Color(0xFFF5F5F5); // Light Gray/White
  static const Color cardBackground = Colors.white;
  static const Color textDark = Color(0xFF3E2723); // Dark Brown
  static const Color textLight = Color(0xFF8D6E63);
  static const Color accent = Color(0xFF795548);

  static const Color stepIndicatorActive = Color(0xFF795548);
  static const Color stepIndicatorInactive = Color(0xFFE0E0E0);
}

class WizardStyles {
  static TextStyle get titleLarge => GoogleFonts.outfit(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        color: WizardColors.textDark,
      );

  static TextStyle get titleMedium => GoogleFonts.outfit(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: WizardColors.textDark,
      );

  static TextStyle get labelLarge => GoogleFonts.outfit(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: WizardColors.textDark,
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: WizardColors.cardBackground,
        borderRadius: BorderRadius.circular(24.r), // Very rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: WizardColors.primarySpring,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 32.w),
        textStyle: GoogleFonts.outfit(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      );

  static ButtonStyle get secondaryButtonStyle => TextButton.styleFrom(
        foregroundColor: WizardColors.textLight,
        textStyle: GoogleFonts.outfit(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      );
}

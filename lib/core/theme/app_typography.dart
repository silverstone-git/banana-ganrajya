import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles lifted from `DESIGN.md`.
///
/// Editorial content (headlines, body copy, quotes) uses **Source Serif 4**
/// to evoke the "broadsheet" feel. Interface chrome (nav labels, bylines,
/// metadata, buttons) uses **Work Sans** to keep a clean separation between
/// "content" and "interface" — this distinction is a deliberate brand rule,
/// not a stylistic accident, so keep it consistent when adding new screens.
class AppTypography {
  AppTypography._();

  static TextStyle get displayLg => GoogleFonts.sourceSerif4(
        fontSize: 40,
        height: 48 / 40,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineLg => GoogleFonts.sourceSerif4(
        fontSize: 30,
        height: 38 / 30,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      );

  /// Mobile-scaled headline — this is the one used for hero/article titles
  /// on phone-sized viewports in the mockups.
  static TextStyle get headlineLgMobile => GoogleFonts.sourceSerif4(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.sourceSerif4(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyLg => GoogleFonts.sourceSerif4(
        fontSize: 18,
        height: 30 / 18,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get bodyMd => GoogleFonts.sourceSerif4(
        fontSize: 16,
        height: 26 / 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      );

  static TextStyle get labelLg => GoogleFonts.workSans(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle get labelMd => GoogleFonts.workSans(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 1,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceVariant,
      );
}

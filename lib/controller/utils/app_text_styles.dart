import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Manrope for headings (AppBar "AURA", page titles, perfume names)
  static TextStyle _manrope({
    required double size,
    required FontWeight weight,
    required Color color,
    double height = 1.0,
    double letterSpacing = 0.0,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // Plus Jakarta Sans for everything else (body, labels, navbar, chips)
  static TextStyle _jakarta({
    required double size,
    required FontWeight weight,
    required Color color,
    double height = 1.0,
    double letterSpacing = 0.0,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // ── Headings (Manrope) ──────────────────────────────────────────────────────
  static TextStyle get appWordmark => _manrope(
        size: 17.sp,
        weight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 6,
        height: 1.0,
      );

  static TextStyle get screenTitle => _manrope(
        size: 24.sp,
        weight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.05,
      );

  static TextStyle get perfumeName => _manrope(
        size: 18.sp,
        weight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  // ── Body / Labels (Plus Jakarta Sans) ───────────────────────────────────────
  static TextStyle get body => _jakarta(
        size: 15.sp,
        weight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get bodyMuted => body.copyWith(color: AppColors.textSecondary);

  static TextStyle get caption => _jakarta(
        size: 12.5.sp,
        weight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
        height: 1.2,
      );

  static TextStyle get chip => _jakarta(
        size: 13.sp,
        weight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.0,
      );

  static TextStyle get buttonPrimary => _jakarta(
        size: 15.5.sp,
        weight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 2.0,
        height: 1.0,
      );

  static TextStyle get buttonSecondary => _jakarta(
        size: 14.5.sp,
        weight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 1.5,
        height: 1.0,
      );

  static TextStyle get navLabel => _jakarta(
        size: 12.sp,
        weight: FontWeight.w800,
        color: AppColors.textSecondary,
        height: 1.0,
      );

  static TextStyle get navLabelActive =>
      navLabel.copyWith(color: AppColors.primary);

  static TextTheme toTextTheme(TextTheme base) => base.copyWith(
        displayLarge: screenTitle,
        titleLarge: perfumeName,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: buttonPrimary,
        labelMedium: navLabel,
      );
}
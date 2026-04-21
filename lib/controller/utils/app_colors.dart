import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand / Core (picked to match the screenshots: deep navy + soft neutrals)
  static const Color primary = Color(0xFF0B2D8F);
  static const Color primaryDark = Color(0xFF071F63);
  static const Color primarySoft = Color(0xFFDDE6FF);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2A5CFF),
      Color(0xFF0B2D8F),
      Color(0xFF071F63),
    ],
  );

  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F2F7);

  static const Color textPrimary = Color(0xFF0B1634);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9AA3B2);

  static const Color border = Color(0xFFE5E7EF);
  static const Color shadow = Color(0x1A0B1634);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Ratings / accents
  static const Color starActive = Color(0xFF9AA9FF);
  static const Color starInactive = Color(0xFFD6DBE8);
}
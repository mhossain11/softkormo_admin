import 'package:flutter/material.dart';

/// Central color tokens for the SoftKormo admin panel.
///
/// Brand colors are used for primary actions, active navigation and
/// highlights. Everything else stays neutral so data remains the focus.
class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFF0B3C88);
  static const Color primaryDark = Color(0xFF093069);
  static const Color primaryLight = Color(0xFFE8EEF8);
  static const Color accent = Color(0xFF00B894);
  static const Color accentLight = Color(0xFFE3F8F3);

  // Light surfaces
  static const Color background = Color(0xFFF4F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF9FAFC);
  static const Color border = Color(0xFFE3E7EE);
  static const Color borderStrong = Color(0xFFCBD2DC);

  // Text
  static const Color textPrimary = Color(0xFF16202E);
  static const Color textSecondary = Color(0xFF5B6676);
  static const Color textMuted = Color(0xFF8A93A3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF10141B);
  static const Color darkSurface = Color(0xFF171C25);
  static const Color darkSurfaceAlt = Color(0xFF1D2330);
  static const Color darkBorder = Color(0xFF2A3140);
  static const Color darkTextPrimary = Color(0xFFE8ECF3);
  static const Color darkTextSecondary = Color(0xFF9CA7B8);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFE7F6EC);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFDF2E3);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFCEBEB);
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFE8F0FE);
  static const Color neutral = Color(0xFF64748B);
  static const Color neutralBg = Color(0xFFEDF0F5);

  // Overlays
  static const Color scrim = Color(0x66000000);
  static const Color shadow = Color(0x0F0B1B33);
}

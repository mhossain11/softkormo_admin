import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale used to build the Material 3 text theme.
class AppTypography {
  const AppTypography._();

  static const String? fontFamily = null; // Uses the platform default.

  static const TextTheme textTheme = TextTheme(
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
    bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.45),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: 0.3),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.3, letterSpacing: 0.4),
  );

  static const TextStyle pageSubtitle = TextStyle(fontSize: 13, color: AppColors.textSecondary);
  static const TextStyle cardTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const TextStyle statValue = TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.1);
  static const TextStyle statLabel = TextStyle(fontSize: 12, color: AppColors.textSecondary);
}

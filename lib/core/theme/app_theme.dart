import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Material 3 light/dark themes built from the centralized design tokens.
class AppTheme {
  const AppTheme._();

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primary,
    secondary: AppColors.accent,
    onSecondary: AppColors.textOnPrimary,
    secondaryContainer: AppColors.accentLight,
    onSecondaryContainer: Color(0xFF00705C),
    tertiary: AppColors.info,
    onTertiary: AppColors.textOnPrimary,
    tertiaryContainer: AppColors.infoBg,
    onTertiaryContainer: AppColors.info,
    error: AppColors.danger,
    onError: AppColors.textOnPrimary,
    errorContainer: AppColors.dangerBg,
    onErrorContainer: AppColors.danger,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerHighest: AppColors.surfaceAlt,
    surfaceContainerLow: AppColors.surface,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
    shadow: AppColors.shadow,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.surface,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7FA7E8),
    onPrimary: Color(0xFF06224B),
    primaryContainer: Color(0xFF0B3C88),
    onPrimaryContainer: Color(0xFFDCE7FA),
    secondary: AppColors.accent,
    onSecondary: Color(0xFF00382C),
    secondaryContainer: Color(0xFF005444),
    onSecondaryContainer: AppColors.accentLight,
    tertiary: Color(0xFF7FA7E8),
    onTertiary: Color(0xFF06224B),
    tertiaryContainer: Color(0xFF1B3E72),
    onTertiaryContainer: Color(0xFFDCE7FA),
    error: Color(0xFFF87171),
    onError: Color(0xFF3B0A0A),
    errorContainer: Color(0xFF5B1A1A),
    onErrorContainer: Color(0xFFFECACA),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    onSurfaceVariant: AppColors.darkTextSecondary,
    surfaceContainerHighest: AppColors.darkSurfaceAlt,
    surfaceContainerLow: AppColors.darkSurface,
    outline: Color(0xFF3A4252),
    outlineVariant: AppColors.darkBorder,
    shadow: Colors.black,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.darkTextPrimary,
    onInverseSurface: AppColors.darkSurface,
  );

  static ThemeData light() => _build(_lightScheme, AppColors.background);
  static ThemeData dark() => _build(_darkScheme, AppColors.darkBackground);

  static ThemeData _build(ColorScheme scheme, Color background) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        displayColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkBorder : AppColors.border,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme.titleMedium?.copyWith(color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: TextStyle(
          fontSize: 14,
          color: isDark ? const Color(0xFF6C7686) : AppColors.textMuted,
        ),
        labelStyle: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        floatingLabelStyle: TextStyle(fontSize: 13, color: scheme.primary, fontWeight: FontWeight.w600),
        prefixIconColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        suffixIconColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        errorStyle: const TextStyle(fontSize: 12, height: 1.2),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppDimensions.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppDimensions.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppDimensions.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppDimensions.iconButtonSize, AppDimensions.iconButtonSize),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(fontSize: 14),
        menuStyle: MenuStyle(
          visualDensity: VisualDensity.compact,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: AppRadius.smAll,
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.textPrimary,
        contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        indicatorColor: scheme.primary,
        dividerColor: isDark ? AppColors.darkBorder : AppColors.border,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt),
        headingTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
        dataTextStyle: TextStyle(fontSize: 13, color: scheme.onSurface),
        dataRowColor: WidgetStatePropertyAll(scheme.surface),
        dividerThickness: 1,
        columnSpacing: 24,
        horizontalMargin: 16,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 56,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.textPrimary,
          borderRadius: AppRadius.smAll,
        ),
        textStyle: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smAll,
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        textStyle: TextStyle(fontSize: 13, color: scheme.onSurface),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        iconColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      focusColor: scheme.primary.withValues(alpha: 0.08),
      hoverColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
    );
  }
}

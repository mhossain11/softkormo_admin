import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// The single notification system of the admin panel.
/// Raw Firebase messages must never be shown - callers pass friendly text.
class AppSnackbar {
  const AppSnackbar._();

  static void success(String message) =>
      _show(message, Icons.check_circle_outline_rounded, AppColors.success);

  static void error(String message) =>
      _show(message, Icons.error_outline_rounded, AppColors.danger);

  static void warning(String message) =>
      _show(message, Icons.warning_amber_rounded, AppColors.warning);

  static void info(String message) => _show(message, Icons.info_outline_rounded, AppColors.info);

  static void _show(String message, IconData icon, Color color) {
    final context = Get.context;
    if (context == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 2,
          duration: const Duration(seconds: 4),
          margin: EdgeInsets.symmetric(
            horizontal: math.max(16, (math.min(1440, MediaQuery.sizeOf(context).width - 48) - 480) / 2),
            vertical: 16,
          ),
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

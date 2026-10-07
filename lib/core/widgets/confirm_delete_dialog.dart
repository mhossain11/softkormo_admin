import 'package:flutter/material.dart';

import 'app_button.dart';
import 'app_dialog.dart';

/// Confirmation dialog used before every destructive action.
class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Delete',
  });

  final String title;
  final String message;
  final String confirmLabel;

  /// Returns `true` only when the user confirmed the deletion.
  static Future<bool> show(
    BuildContext context, {
    String title = 'Delete item',
    required String message,
    String confirmLabel = 'Delete',
  }) async {
    final result = await AppDialog.show<bool>(
      context: context,
      title: title,
      width: 440,
      child: Text(message),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.of(context).maybePop(false),
        ),
        AppButton(
          label: confirmLabel,
          variant: AppButtonVariant.danger,
          onPressed: () => Navigator.of(context).maybePop(true),
        ),
      ],
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

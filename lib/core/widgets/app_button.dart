import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }

/// The only button used across the panel. Shows a small progress indicator
/// and disables itself while [loading] (submit protection).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.dense = false,
    this.expanded = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;
  final bool dense;
  final bool expanded;
  final String? tooltip;

  bool get _enabled => !loading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2, color: _spinnerColor),
          )
        else if (icon != null)
          Icon(icon, size: dense ? 15 : 17),
        if (!loading && icon != null) const SizedBox(width: 8),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 10);

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: _enabled ? onPressed : null,
          style: FilledButton.styleFrom(padding: padding),
          child: child,
        ),
      AppButtonVariant.secondary => FilledButton.tonal(
          onPressed: _enabled ? onPressed : null,
          style: FilledButton.styleFrom(padding: padding),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: _enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(padding: padding),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: _enabled ? onPressed : null,
          style: TextButton.styleFrom(padding: padding),
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: _enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            padding: padding,
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          child: child,
        ),
    };

    final result = expanded ? SizedBox(width: double.infinity, child: button) : button;
    if (tooltip == null) return result;
    return Tooltip(message: tooltip!, child: result);
  }

  static const Color _spinnerColor = Colors.white;
}

/// Icon-only button with a mandatory tooltip.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.danger = false,
    this.active = false,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool danger;
  final bool active;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger
        ? AppColors.danger
        : active
            ? scheme.primary
            : scheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: loading || onPressed == null ? null : onPressed,
        iconSize: 18,
        color: color,
        isSelected: active,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
        icon: loading
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
      ),
    );
  }
}

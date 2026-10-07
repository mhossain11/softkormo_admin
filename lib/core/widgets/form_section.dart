import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Titled group of form fields with consistent spacing.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    this.description,
    required this.children,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: scheme.primary),
        ),
        if (description != null) ...[
          AppSpacing.h4,
          Text(
            description!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        AppSpacing.h16,
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) AppSpacing.h16,
          children[i],
        ],
      ],
    );
  }
}

/// Two (or more) form fields side by side; stacks vertically below 520px so
/// nothing overflows on mobile.
class FormRow extends StatelessWidget {
  const FormRow({
    super.key,
    required this.children,
    this.stackBelow = 520,
  }) : assert(children.length > 1);

  final List<Widget> children;
  final double stackBelow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) AppSpacing.h16,
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) AppSpacing.w16,
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

/// Form footer: cancel, save (with progress) and optional delete action.
/// Stacks on narrow screens so nothing overflows on mobile.
class FormActions extends StatelessWidget {
  const FormActions({
    super.key,
    required this.onSave,
    required this.onCancel,
    this.saveLabel = 'Save',
    this.saving = false,
    this.deleteAction,
    this.deleteLabel = 'Delete',
  });

  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String saveLabel;
  final bool saving;
  final VoidCallback? deleteAction;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    final saveButton = AppButton(
      label: saveLabel,
      loading: saving,
      onPressed: saving ? null : onSave,
      icon: Icons.check_rounded,
    );
    final cancelButton = AppButton(
      label: 'Cancel',
      variant: AppButtonVariant.outline,
      onPressed: saving ? null : onCancel,
    );
    final deleteButton = deleteAction == null
        ? null
        : AppButton(
            label: deleteLabel,
            variant: AppButtonVariant.danger,
            icon: Icons.delete_outline_rounded,
            onPressed: saving ? null : deleteAction,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              saveButton,
              AppSpacing.h12,
              Row(
                children: [
                  Expanded(child: cancelButton),
                  if (deleteButton != null) ...[
                    AppSpacing.w12,
                    Expanded(child: deleteButton),
                  ],
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            if (deleteButton != null) ...[
              deleteButton,
              AppSpacing.w16,
            ],
            const Spacer(),
            cancelButton,
            AppSpacing.w12,
            saveButton,
          ],
        );
      },
    );
  }
}

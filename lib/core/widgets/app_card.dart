import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Base card container used everywhere in the panel.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    required this.child,
    this.padding,
    this.clipBehavior = Clip.antiAlias,
  });

  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget child;
  final EdgeInsets? padding;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || (actions?.isNotEmpty ?? false);
    return Card(
      clipBehavior: clipBehavior,
      child: Padding(
        padding: padding ?? AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasHeader) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(title!, style: Theme.of(context).textTheme.titleMedium),
                        if (subtitle != null) ...[
                          AppSpacing.h4,
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions != null && actions!.isNotEmpty) ...[
                    AppSpacing.w16,
                    Wrap(spacing: 8, runSpacing: 8, children: actions!),
                  ],
                ],
              ),
              AppSpacing.h16,
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Card with a required heading - used to group form sections.
class SectionCard extends AppCard {
  const SectionCard({
    super.key,
    required String title,
    String? description,
    required super.child,
    super.actions,
    super.padding,
  }) : super(title: title, subtitle: description);
}

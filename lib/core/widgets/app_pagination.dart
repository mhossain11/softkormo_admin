import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Page footer for every paginated table.
class AppPagination extends StatelessWidget {
  const AppPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
    this.totalItems,
    this.pageSize,
    this.loading = false,
  });

  final int currentPage;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final int? totalItems;
  final int? pageSize;
  final bool loading;

  String get _info {
    final total = totalItems;
    final size = pageSize;
    if (total == null || total <= 0 || size == null) {
      return 'Page $currentPage of $totalPages';
    }
    final first = (currentPage - 1) * size + 1;
    final last = currentPage * size > total ? total : currentPage * size;
    return 'Showing $first–$last of $total';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previous = AppButton(
      label: 'Previous',
      dense: true,
      variant: AppButtonVariant.outline,
      icon: Icons.chevron_left_rounded,
      loading: loading && hasPrevious,
      onPressed: hasPrevious ? onPrevious : null,
    );
    final next = AppButton(
      label: 'Next',
      dense: true,
      variant: AppButtonVariant.outline,
      icon: Icons.chevron_right_rounded,
      loading: loading && hasNext,
      onPressed: hasNext ? onNext : null,
    );
    final pageText = Text(
      'Page $currentPage of $totalPages',
      style: theme.textTheme.bodySmall,
    );
    // Wrapping keeps the three controls on one line when there is room and
    // stacks them instead of overflowing on narrow screens.
    final buttons = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [previous, pageText, next],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final info = Text(_info, style: theme.textTheme.bodySmall);
        if (constraints.maxWidth < AppPagination._stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              info,
              AppSpacing.h12,
              buttons,
            ],
          );
        }
        return Row(
          children: [
            info,
            AppSpacing.w16,
            // Flexible keeps the buttons on one line when there is room and
            // lets them wrap instead of overflowing when there is not.
            Flexible(
              child: Align(alignment: Alignment.centerRight, child: buttons),
            ),
          ],
        );
      },
    );
  }

  /// Below this width the summary and the buttons are stacked.
  static const double _stackBelow = 600;
}

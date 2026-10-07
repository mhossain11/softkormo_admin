import 'package:flutter/material.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_dimensions.dart';
import 'app_states.dart';

/// One column of an [AppDataTable].
class AppTableColumn<T> {
  const AppTableColumn({
    required this.label,
    required this.cell,
    this.width,
    this.numeric = false,
  });

  final String label;
  final Widget Function(T item) cell;
  final double? width;
  final bool numeric;
}

/// The single table architecture of the panel.
///
/// Desktop/tablet: material [DataTable] inside a horizontal scroll view.
/// Mobile (< 768px): cards built by [mobileBuilder].
/// Loading, error and empty states are handled here as well, so every list
/// screen behaves identically.
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowKey,
    required this.mobileBuilder,
    this.onRowTap,
    this.loading = false,
    this.errorMessage,
    this.onRetry,
    this.emptyTitle = 'No results',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyAction,
    this.onEmptyAction,
    this.tableMinWidth = AppDimensions.tableScrollMinWidth,
  });

  final List<AppTableColumn<T>> columns;
  final List<T> rows;
  final String Function(T item) rowKey;
  final Widget Function(T item, int index) mobileBuilder;
  final ValueChanged<T>? onRowTap;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final String? emptyAction;
  final VoidCallback? onEmptyAction;
  final double tableMinWidth;

  @override
  Widget build(BuildContext context) {
    if (loading) return const TableLoadingState();
    if (errorMessage != null) {
      return ErrorState(message: errorMessage!, onRetry: onRetry);
    }
    if (rows.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
        actionLabel: emptyAction,
        onAction: onEmptyAction,
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            mobileBuilder(rows[i], i),
          ],
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: tableMinWidth),
        child: DataTable(
          columns: [
            for (final column in columns)
              DataColumn(label: Text(column.label), numeric: column.numeric),
          ],
          rows: [
            for (final item in rows)
              DataRow(
                key: ValueKey(rowKey(item)),
                onSelectChanged: onRowTap == null ? null : (_) => onRowTap!(item),
                cells: [
                  for (final column in columns)
                    DataCell(
                      column.width == null
                          ? column.cell(item)
                          : SizedBox(width: column.width, child: column.cell(item)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

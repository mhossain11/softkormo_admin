import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/shell_controller.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_page_header.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_pagination.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/flag_filter.dart';
import '../../../core/widgets/list_toolbar.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/package_plan.dart';
import 'package_controller.dart';

/// Packages CMS list: search, active filter, activate/recommended toggles,
/// reorder and delete.
class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  late final PackageController _controller = getIt<PackageController>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.ensureLoaded();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openForm({PackagePlan? plan}) {
    getIt<ShellController>().pushPage(
      plan == null ? Routes.packageNew : Routes.packageEdit,
      arguments: plan,
    );
  }

  Future<void> _confirmDelete(PackagePlan plan) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete package',
      message: 'Delete "${plan.name}"? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    await _controller.deleteItem(plan.id);
  }

  void _clearFilters() {
    _searchController.clear();
    _controller.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(
            title: 'Packages',
            subtitle: 'Pricing plans shown on the website - any number of plans',
            actions: [
              AppButton(
                label: 'New package',
                icon: Icons.add_rounded,
                onPressed: () => _openForm(),
              ),
              AppIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh list',
                onPressed: _controller.reload,
              ),
            ],
          ),
          AppCard(
            title: 'All packages',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  final value = _controller.filter.value;
                  return ListToolbar(
                    searchController: _searchController,
                    searchHint: 'Search packages...',
                    onSearchChanged: _controller.onSearchChanged,
                    hasActiveFilters: _controller.hasActiveFilters,
                    onClearFilters: _clearFilters,
                    filter: FlagFilter(
                      value: value is bool ? value : null,
                      allLabel: 'All packages',
                      trueLabel: 'Active',
                      falseLabel: 'Inactive',
                      onChanged: _controller.setFilter,
                    ),
                  );
                }),
                AppSpacing.h16,
                Obx(() => AppDataTable<PackagePlan>(
                      columns: _columns(),
                      rows: _controller.items.toList(),
                      rowKey: (plan) => plan.id,
                      mobileBuilder: (plan, index) => _PackageCard(
                        plan: plan,
                        index: index,
                        controller: _controller,
                        onEdit: () => _openForm(plan: plan),
                        onDelete: () => _confirmDelete(plan),
                      ),
                      loading: _controller.loading.value,
                      errorMessage: _controller.errorMessage.value,
                      onRetry: _controller.reload,
                      emptyTitle: _controller.hasActiveFilters
                          ? 'No packages match your filters'
                          : 'No packages yet',
                      emptyAction:
                          _controller.hasActiveFilters ? 'Clear filters' : 'New package',
                      onEmptyAction: _controller.hasActiveFilters
                          ? _clearFilters
                          : () => _openForm(),
                      emptyIcon: Icons.sell_outlined,
                    )),
                AppSpacing.h16,
                Obx(() => AppPagination(
                      currentPage: _controller.currentPage,
                      totalPages: _controller.totalPages,
                      totalItems: _controller.total.value,
                      pageSize: _controller.pageSize,
                      hasPrevious: _controller.canGoPrevious,
                      hasNext: _controller.canGoNext,
                      loading: _controller.loading.value,
                      onPrevious: _controller.previousPage,
                      onNext: _controller.nextPage,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<AppTableColumn<PackagePlan>> _columns() => [
        AppTableColumn<PackagePlan>(
          label: 'Package',
          width: 260,
          cell: (plan) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                plan.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (plan.subtitle.isNotEmpty)
                Text(
                  plan.subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5B6676)),
                ),
            ],
          ),
        ),
        AppTableColumn<PackagePlan>(
          label: 'Price',
          width: 130,
          cell: (plan) => Text(
            Formatters.money(plan.price, plan.currency),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        AppTableColumn<PackagePlan>(
          label: 'Status',
          width: 200,
          cell: (plan) => Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              StatusChip.of(plan.active ? 'active' : 'inactive', dense: true),
              if (plan.recommended) StatusChip.of('recommended', dense: true),
            ],
          ),
        ),
        AppTableColumn<PackagePlan>(
          label: 'Order',
          width: 70,
          cell: (plan) => Text('#${plan.order}', style: const TextStyle(fontSize: 13)),
        ),
        AppTableColumn<PackagePlan>(
          label: 'Actions',
          width: 170,
          cell: (plan) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit package',
                onPressed: () => _openForm(plan: plan),
              ),
              Obx(() => AppIconButton(
                    icon: Icons.toggle_on_outlined,
                    tooltip: plan.active ? 'Deactivate' : 'Activate',
                    active: plan.active,
                    onPressed: () => _controller.toggleActive(plan),
                  )),
              Obx(() => AppIconButton(
                    icon: Icons.star_outline_rounded,
                    tooltip: plan.recommended
                        ? 'Remove recommended flag'
                        : 'Mark as recommended',
                    active: plan.recommended,
                    onPressed: () => _controller.toggleRecommended(plan),
                  )),
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete package',
                danger: true,
                onPressed: () => _confirmDelete(plan),
              ),
            ],
          ),
        ),
      ];
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.plan,
    required this.index,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final PackagePlan plan;
  final int index;
  final PackageController controller;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${Formatters.money(plan.price, plan.currency)}'
                          '${plan.billingLabel.isEmpty ? '' : ' / ${plan.billingLabel}'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip.of(plan.active ? 'active' : 'inactive', dense: true),
                ],
              ),
              AppSpacing.h12,
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (plan.recommended) StatusChip.of('recommended', dense: true),
                        StatusChip(
                          label: '#${plan.order}',
                          color: theme.colorScheme.onSurfaceVariant,
                          background: theme.colorScheme.surfaceContainerHighest,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.arrow_upward_rounded,
                    tooltip: 'Move up',
                    onPressed: index == 0 ? null : () => controller.moveItem(index, -1),
                  ),
                  AppIconButton(
                    icon: Icons.arrow_downward_rounded,
                    tooltip: 'Move down',
                    onPressed: () => controller.moveItem(index, 1),
                  ),
                  AppIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit package',
                    onPressed: onEdit,
                  ),
                  AppIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete package',
                    danger: true,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

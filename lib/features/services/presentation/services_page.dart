import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/shell_controller.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_spacing.dart';
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
import '../domain/service_item.dart';
import 'service_controller.dart';

/// Services CMS list: search, publish filter, publish toggle, reorder, delete.
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late final ServiceController _controller = getIt<ServiceController>();
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

  void _openForm({ServiceItem? service}) {
    getIt<ShellController>().pushPage(
      service == null ? Routes.serviceNew : Routes.serviceEdit,
      arguments: service,
    );
  }

  Future<void> _confirmDelete(ServiceItem service) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete service',
      message: 'Delete "${service.title}"? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    await _controller.deleteItem(service.id);
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
            title: 'Services',
            subtitle: 'Services offered to website visitors',
            actions: [
              AppButton(
                label: 'New service',
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
            title: 'All services',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  final value = _controller.filter.value;
                  return ListToolbar(
                    searchController: _searchController,
                    searchHint: 'Search services...',
                    onSearchChanged: _controller.onSearchChanged,
                    hasActiveFilters: _controller.hasActiveFilters,
                    onClearFilters: _clearFilters,
                    filter: FlagFilter(
                      value: value is bool ? value : null,
                      allLabel: 'All services',
                      trueLabel: 'Published',
                      falseLabel: 'Unpublished',
                      onChanged: _controller.setFilter,
                    ),
                  );
                }),
                AppSpacing.h16,
                Obx(() => AppDataTable<ServiceItem>(
                      columns: _columns(),
                      rows: _controller.items.toList(),
                      rowKey: (service) => service.id,
                      mobileBuilder: (service, index) => _ServiceCard(
                        service: service,
                        index: index,
                        controller: _controller,
                        onEdit: () => _openForm(service: service),
                        onDelete: () => _confirmDelete(service),
                      ),
                      loading: _controller.loading.value,
                      errorMessage: _controller.errorMessage.value,
                      onRetry: _controller.reload,
                      emptyTitle: _controller.hasActiveFilters
                          ? 'No services match your filters'
                          : 'No services yet',
                      emptyAction:
                          _controller.hasActiveFilters ? 'Clear filters' : 'New service',
                      onEmptyAction: _controller.hasActiveFilters
                          ? _clearFilters
                          : () => _openForm(),
                      emptyIcon: Icons.design_services_outlined,
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

  List<AppTableColumn<ServiceItem>> _columns() => [
        AppTableColumn<ServiceItem>(
          label: 'Service',
          width: 340,
          cell: (service) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                service.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (service.shortDescription.isNotEmpty)
                Text(
                  service.shortDescription,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5B6676)),
                ),
            ],
          ),
        ),
        AppTableColumn<ServiceItem>(
          label: 'Features',
          width: 90,
          cell: (service) => Text(
            '${service.features.length}',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        AppTableColumn<ServiceItem>(
          label: 'Status',
          width: 130,
          cell: (service) => StatusChip.of(
            service.published ? 'published' : 'unpublished',
          ),
        ),
        AppTableColumn<ServiceItem>(
          label: 'Order',
          width: 70,
          cell: (service) => Text(
            '#${service.order}',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        AppTableColumn<ServiceItem>(
          label: 'Actions',
          width: 130,
          cell: (service) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit service',
                onPressed: () => _openForm(service: service),
              ),
              Obx(() => AppIconButton(
                    icon: service.published
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    tooltip: service.published ? 'Unpublish' : 'Publish',
                    active: service.published,
                    onPressed: () => _controller.togglePublished(service),
                  )),
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete service',
                danger: true,
                onPressed: () => _confirmDelete(service),
              ),
            ],
          ),
        ),
      ];
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.index,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final ServiceItem service;
  final int index;
  final ServiceController controller;
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
                          service.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (service.shortDescription.isNotEmpty)
                          Text(
                            service.shortDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  StatusChip.of(
                    service.published ? 'published' : 'unpublished',
                    dense: true,
                  ),
                ],
              ),
              AppSpacing.h12,
              Row(
                children: [
                  Expanded(
                    child: StatusChip(
                      label: '#${service.order} · ${service.features.length} features',
                      color: theme.colorScheme.onSurfaceVariant,
                      background: theme.colorScheme.surfaceContainerHighest,
                      dense: true,
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
                    tooltip: 'Edit service',
                    onPressed: onEdit,
                  ),
                  AppIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete service',
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

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
import '../../../core/widgets/network_image_view.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/testimonial.dart';
import 'testimonial_controller.dart';

/// Testimonials CMS list: search, publish filter, toggles, reorder, delete.
class TestimonialsPage extends StatefulWidget {
  const TestimonialsPage({super.key});

  @override
  State<TestimonialsPage> createState() => _TestimonialsPageState();
}

class _TestimonialsPageState extends State<TestimonialsPage> {
  late final TestimonialController _controller = getIt<TestimonialController>();
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

  void _openForm({Testimonial? testimonial}) {
    getIt<ShellController>().pushPage(
      testimonial == null ? Routes.testimonialNew : Routes.testimonialEdit,
      arguments: testimonial,
    );
  }

  Future<void> _confirmDelete(Testimonial testimonial) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete testimonial',
      message: 'Delete the testimonial from ${testimonial.name}?',
    );
    if (!confirmed || !mounted) return;
    await _controller.deleteItem(testimonial.id);
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
            title: 'Testimonials',
            subtitle: 'Customer feedback shown on the website',
            actions: [
              AppButton(
                label: 'New testimonial',
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
            title: 'All testimonials',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  final value = _controller.filter.value;
                  return ListToolbar(
                    searchController: _searchController,
                    searchHint: 'Search by name...',
                    onSearchChanged: _controller.onSearchChanged,
                    hasActiveFilters: _controller.hasActiveFilters,
                    onClearFilters: _clearFilters,
                    filter: FlagFilter(
                      value: value is bool ? value : null,
                      allLabel: 'All testimonials',
                      trueLabel: 'Published',
                      falseLabel: 'Unpublished',
                      onChanged: _controller.setFilter,
                    ),
                  );
                }),
                AppSpacing.h16,
                Obx(() => AppDataTable<Testimonial>(
                      columns: _columns(),
                      rows: _controller.items.toList(),
                      rowKey: (testimonial) => testimonial.id,
                      mobileBuilder: (testimonial, index) => _TestimonialCard(
                        testimonial: testimonial,
                        index: index,
                        controller: _controller,
                        onEdit: () => _openForm(testimonial: testimonial),
                        onDelete: () => _confirmDelete(testimonial),
                      ),
                      loading: _controller.loading.value,
                      errorMessage: _controller.errorMessage.value,
                      onRetry: _controller.reload,
                      emptyTitle: _controller.hasActiveFilters
                          ? 'No testimonials match your filters'
                          : 'No testimonials yet',
                      emptyAction: _controller.hasActiveFilters
                          ? 'Clear filters'
                          : 'New testimonial',
                      onEmptyAction: _controller.hasActiveFilters
                          ? _clearFilters
                          : () => _openForm(),
                      emptyIcon: Icons.format_quote_rounded,
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

  List<AppTableColumn<Testimonial>> _columns() => [
        AppTableColumn<Testimonial>(
          label: 'Customer',
          width: 260,
          cell: (testimonial) => Row(
            children: [
              InitialAvatar(name: testimonial.name, url: testimonial.imageUrl),
              AppSpacing.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      testimonial.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      [
                        if (testimonial.designation.isNotEmpty) testimonial.designation,
                        if (testimonial.company.isNotEmpty) testimonial.company,
                      ].join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5B6676)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppTableColumn<Testimonial>(
          label: 'Rating',
          width: 110,
          cell: (testimonial) => _Rating(value: testimonial.rating),
        ),
        AppTableColumn<Testimonial>(
          label: 'Status',
          width: 190,
          cell: (testimonial) => Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              StatusChip.of(
                testimonial.published ? 'published' : 'unpublished',
                dense: true,
              ),
              if (testimonial.featured) StatusChip.of('featured', dense: true),
            ],
          ),
        ),
        AppTableColumn<Testimonial>(
          label: 'Order',
          width: 70,
          cell: (testimonial) => Text(
            '#${testimonial.order}',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        AppTableColumn<Testimonial>(
          label: 'Actions',
          width: 170,
          cell: (testimonial) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit testimonial',
                onPressed: () => _openForm(testimonial: testimonial),
              ),
              Obx(() => AppIconButton(
                    icon: testimonial.published
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    tooltip: testimonial.published ? 'Unpublish' : 'Publish',
                    active: testimonial.published,
                    onPressed: () => _controller.togglePublished(testimonial),
                  )),
              Obx(() => AppIconButton(
                    icon: Icons.star_outline_rounded,
                    tooltip: testimonial.featured
                        ? 'Remove from featured'
                        : 'Mark as featured',
                    active: testimonial.featured,
                    onPressed: () => _controller.toggleFeatured(testimonial),
                  )),
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete testimonial',
                danger: true,
                onPressed: () => _confirmDelete(testimonial),
              ),
            ],
          ),
        ),
      ];
}

class _Rating extends StatelessWidget {
  const _Rating({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= Testimonial.maxRating; i++)
          Icon(
            i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 15,
            color: i <= value ? const Color(0xFFF5A524) : const Color(0xFF9AA3B2),
          ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({
    required this.testimonial,
    required this.index,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final Testimonial testimonial;
  final int index;
  final TestimonialController controller;
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
                  InitialAvatar(name: testimonial.name, url: testimonial.imageUrl),
                  AppSpacing.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testimonial.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          [
                            if (testimonial.designation.isNotEmpty) testimonial.designation,
                            if (testimonial.company.isNotEmpty) testimonial.company,
                          ].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip.of(
                    testimonial.published ? 'published' : 'unpublished',
                    dense: true,
                  ),
                ],
              ),
              AppSpacing.h12,
              Text(
                testimonial.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              AppSpacing.h12,
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Rating(value: testimonial.rating),
                        if (testimonial.featured) StatusChip.of('featured', dense: true),
                        StatusChip(
                          label: '#${testimonial.order}',
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
                    tooltip: 'Edit testimonial',
                    onPressed: onEdit,
                  ),
                  AppIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete testimonial',
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

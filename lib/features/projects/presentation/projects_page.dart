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
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_pagination.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/list_toolbar.dart';
import '../../../core/widgets/network_image_view.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/project.dart';
import 'project_controller.dart';

/// Project CMS list: search, category filter, publish/feature toggles,
/// reorder and delete.
class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late final ProjectController _controller = getIt<ProjectController>();
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

  void _openForm({Project? project}) {
    getIt<ShellController>().pushPage(
      project == null ? Routes.projectNew : Routes.projectEdit,
      arguments: project,
    );
  }

  Future<void> _confirmDelete(Project project) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete project',
      message: 'Delete "${project.title}"? Its images will also be removed from storage.',
    );
    if (!confirmed || !mounted) return;
    await _controller.deleteItem(project.id);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(
            title: 'Projects',
            subtitle: 'Portfolio entries shown on the public website',
            actions: [
              AppButton(
                label: 'New project',
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
            title: 'All projects',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  final categories = _controller.categories;
                  final current = _controller.filter.value;
                  return ListToolbar(
                    searchController: _searchController,
                    searchHint: 'Search projects...',
                    onSearchChanged: _controller.onSearchChanged,
                    hasActiveFilters: _controller.hasActiveFilters,
                    onClearFilters: _clearFilters,
                    filter: AppDropdown<String?>(
                      value: current is String && categories.contains(current)
                          ? current
                          : null,
                      hint: 'All categories',
                      width: 200,
                      items: [
                        const DropdownItem<String?>(value: null, label: 'All categories'),
                        for (final category in categories)
                          DropdownItem<String?>(value: category, label: category),
                      ],
                      onChanged: _controller.setFilter,
                    ),
                  );
                }),
                AppSpacing.h16,
                Obx(() => AppDataTable<Project>(
                      columns: _columns(),
                      rows: _controller.items.toList(),
                      rowKey: (project) => project.id,
                      mobileBuilder: (project, index) => _ProjectCard(
                        project: project,
                        index: index,
                        controller: _controller,
                        onEdit: () => _openForm(project: project),
                        onDelete: () => _confirmDelete(project),
                      ),
                      loading: _controller.loading.value,
                      errorMessage: _controller.errorMessage.value,
                      onRetry: _controller.reload,
                      emptyTitle: _controller.hasActiveFilters
                          ? 'No projects match your filters'
                          : 'No projects yet',
                      emptyAction: _controller.hasActiveFilters ? 'Clear filters' : 'New project',
                      onEmptyAction: _controller.hasActiveFilters
                          ? _clearFilters
                          : () => _openForm(),
                      emptyIcon: Icons.work_outline_rounded,
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

  void _clearFilters() {
    _searchController.clear();
    _controller.clearFilters();
  }

  List<AppTableColumn<Project>> _columns() => [
        AppTableColumn<Project>(
          label: 'Project',
          width: 300,
          cell: (project) => Row(
            children: [
              NetworkImageView(
                url: project.thumbnail,
                width: 44,
                height: 32,
                radius: 6,
                memCacheWidth: 120,
              ),
              AppSpacing.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      project.slug.isEmpty ? project.category : project.slug,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5B6676)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppTableColumn<Project>(
          label: 'Category',
          width: 130,
          cell: (project) => Text(
            project.category.isEmpty ? '—' : project.category,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        AppTableColumn<Project>(
          label: 'Year',
          width: 70,
          cell: (project) => Text(
            project.year?.toString() ?? '—',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        AppTableColumn<Project>(
          label: 'Status',
          width: 190,
          cell: (project) => Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              StatusChip.of(project.published ? 'published' : 'unpublished', dense: true),
              if (project.featured) StatusChip.of('featured', dense: true),
            ],
          ),
        ),
        AppTableColumn<Project>(
          label: 'Actions',
          width: 170,
          cell: (project) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit project',
                onPressed: () => _openForm(project: project),
              ),
              Obx(() => AppIconButton(
                    icon: project.published
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    tooltip: project.published ? 'Unpublish' : 'Publish',
                    active: project.published,
                    onPressed: () => _controller.togglePublished(project),
                  )),
              Obx(() => AppIconButton(
                    icon: Icons.star_outline_rounded,
                    tooltip: project.featured ? 'Remove from featured' : 'Mark as featured',
                    active: project.featured,
                    onPressed: () => _controller.toggleFeatured(project),
                  )),
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete project',
                danger: true,
                onPressed: () => _confirmDelete(project),
              ),
            ],
          ),
        ),
      ];
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.index,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final Project project;
  final int index;
  final ProjectController controller;
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
                  NetworkImageView(
                    url: project.thumbnail,
                    width: 56,
                    height: 40,
                    radius: 6,
                    memCacheWidth: 160,
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          [
                            if (project.category.isNotEmpty) project.category,
                            if (project.year != null) project.year.toString(),
                          ].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip.of(project.published ? 'published' : 'unpublished', dense: true),
                ],
              ),
              if (project.shortDescription.isNotEmpty) ...[
                AppSpacing.h12,
                Text(
                  project.shortDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              AppSpacing.h12,
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (project.featured) StatusChip.of('featured', dense: true),
                        StatusChip(
                          label: '#${project.order}',
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
                    tooltip: 'Edit project',
                    onPressed: onEdit,
                  ),
                  AppIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete project',
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

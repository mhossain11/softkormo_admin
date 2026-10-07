import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
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
import '../domain/contact.dart';
import 'contact_controller.dart';
import 'contact_details_dialog.dart';

/// Contact inbox (CRM): search, status filter, pagination, details, delete.
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  late final ContactController _controller = getIt<ContactController>();
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

  Future<void> _confirmDelete(Contact contact) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete contact',
      message: 'Delete the enquiry from ${contact.name}? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    await _controller.deleteItem(contact.id);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(
            title: 'Contacts',
            subtitle: 'Leads submitted through the website contact form',
            actions: [
              AppIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh list',
                onPressed: _controller.reload,
              ),
            ],
          ),
          AppCard(
            title: 'All contacts',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() => ListToolbar(
                      searchController: _searchController,
                      searchHint: 'Search by name...',
                      onSearchChanged: _controller.onSearchChanged,
                      hasActiveFilters: _controller.hasActiveFilters,
                      onClearFilters: _clearFilters,
                      filter: AppDropdown<String?>(
                        value: _controller.statusFilter,
                        hint: 'All statuses',
                        width: 190,
                        items: [
                          const DropdownItem<String?>(value: null, label: 'All statuses'),
                          for (final status in _controller.availableStatuses)
                            DropdownItem<String?>(
                              value: status,
                              label: StatusStyles.meta(status).label,
                            ),
                        ],
                        onChanged: _controller.setFilter,
                      ),
                    )),
                AppSpacing.h16,
                Obx(() => AppDataTable<Contact>(
                      columns: _columns(),
                      rows: _controller.items.toList(),
                      rowKey: (contact) => contact.id,
                      mobileBuilder: (contact, _) => _ContactCard(
                        contact: contact,
                        onOpen: () => showContactDetailsDialog(context, _controller, contact),
                        onDelete: () => _confirmDelete(contact),
                      ),
                      onRowTap: (contact) => showContactDetailsDialog(context, _controller, contact),
                      loading: _controller.loading.value,
                      errorMessage: _controller.errorMessage.value,
                      onRetry: _controller.reload,
                      emptyTitle: _controller.hasActiveFilters
                          ? 'No contacts match your filters'
                          : 'No contacts yet',
                      emptyMessage: _controller.hasActiveFilters
                          ? 'Try a different search term or status.'
                          : 'Submissions from the website will appear here.',
                      emptyIcon: Icons.mail_outline_rounded,
                      emptyAction: _controller.hasActiveFilters ? 'Clear filters' : null,
                      onEmptyAction: _controller.hasActiveFilters ? _clearFilters : null,
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

  List<AppTableColumn<Contact>> _columns() => [
        AppTableColumn<Contact>(
          label: 'Contact',
          width: 250,
          cell: (contact) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                contact.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (contact.email.isNotEmpty)
                Text(
                  contact.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5B6676)),
                ),
            ],
          ),
        ),
        AppTableColumn<Contact>(
          label: 'Phone',
          width: 140,
          cell: (contact) => Text(
            contact.phone.isEmpty ? '—' : contact.phone,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        AppTableColumn<Contact>(
          label: 'Service',
          width: 150,
          cell: (contact) => Text(
            contact.service.isEmpty ? '—' : contact.service,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        AppTableColumn<Contact>(
          label: 'Status',
          width: 130,
          cell: (contact) => StatusChip.of(contact.status),
        ),
        AppTableColumn<Contact>(
          label: 'Received',
          width: 110,
          cell: (contact) => Text(
            Formatters.relativeTime(contact.createdAt),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        AppTableColumn<Contact>(
          label: '',
          width: 100,
          cell: (contact) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconButton(
                icon: Icons.visibility_outlined,
                tooltip: 'View details',
                onPressed: () {
                  if (mounted) showContactDetailsDialog(context, _controller, contact);
                },
              ),
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete contact',
                danger: true,
                onPressed: () => _confirmDelete(contact),
              ),
            ],
          ),
        ),
      ];
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onOpen,
    required this.onDelete,
  });

  final Contact contact;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InitialAvatar(name: contact.name),
                  AppSpacing.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (contact.email.isNotEmpty)
                          Text(
                            contact.email,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  StatusChip.of(contact.status, dense: true),
                ],
              ),
              AppSpacing.h12,
              Row(
                children: [
                  if (contact.service.isNotEmpty) ...[
                    const Icon(Icons.sell_outlined, size: 13, color: Color(0xFF5B6676)),
                    AppSpacing.w4,
                    Expanded(
                      child: Text(
                        contact.service,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5B6676)),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (contact.phone.isNotEmpty)
                    Text(
                      contact.phone,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5B6676)),
                    ),
                ],
              ),
              AppSpacing.h12,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.relativeTime(contact.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIconButton(
                        icon: Icons.visibility_outlined,
                        tooltip: 'View details',
                        onPressed: onOpen,
                      ),
                      AppIconButton(
                        icon: Icons.delete_outline_rounded,
                        tooltip: 'Delete contact',
                        danger: true,
                        onPressed: onDelete,
                      ),
                    ],
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

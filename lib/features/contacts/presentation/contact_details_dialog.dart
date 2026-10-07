import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../domain/contact.dart';
import 'contact_controller.dart';

/// Opens the details dialog of a lead and allows status updates / deletion.
Future<void> showContactDetailsDialog(
  BuildContext context,
  ContactController controller,
  Contact contact,
) {
  return AppDialog.show<void>(
    context: context,
    title: 'Contact details',
    width: 560,
    child: _ContactDetails(controller: controller, contact: contact),
  );
}

class _ContactDetails extends StatefulWidget {
  const _ContactDetails({required this.controller, required this.contact});

  final ContactController controller;
  final Contact contact;

  @override
  State<_ContactDetails> createState() => _ContactDetailsState();
}

class _ContactDetailsState extends State<_ContactDetails> {
  late String _status = widget.contact.status;
  bool _saving = false;

  Future<void> _updateStatus() async {
    if (_saving) return;
    setState(() => _saving = true);
    final success = await widget.controller.updateStatus(widget.contact, _status);
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) Navigator.of(context).maybePop();
  }

  Future<void> _delete() async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete contact'),
        content: Text('Delete the enquiry from ${widget.contact.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).maybePop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(dialogContext).maybePop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    final success = await widget.controller.deleteItem(widget.contact.id);
    if (!mounted) return;
    if (success) Navigator.of(context).maybePop();
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contact = widget.contact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(label: 'Name', value: contact.name),
        _InfoRow(label: 'Email', value: contact.email),
        _InfoRow(label: 'Phone', value: contact.phone),
        _InfoRow(label: 'Service', value: contact.service),
        _InfoRow(label: 'Source', value: contact.source),
        _InfoRow(label: 'Received', value: Formatters.dateTimeOrDash(contact.createdAt)),
        AppSpacing.h16,
        Text('Message', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        AppSpacing.h8,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: contact.message.isEmpty
              ? Text('—', style: theme.textTheme.bodyMedium)
              : SelectableText(
                  contact.message,
                  style: theme.textTheme.bodyMedium,
                ),
        ),
        AppSpacing.h24,
        Divider(color: theme.colorScheme.outlineVariant),
        AppSpacing.h16,
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppDropdown<String>(
              value: _status,
              width: 180,
              label: 'Status',
              items: [
                for (final status in Contact.statuses)
                  DropdownItem<String>(value: status, label: status[0].toUpperCase() + status.substring(1)),
              ],
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            AppButton(
              label: 'Update status',
              loading: _saving,
              onPressed: _saving ? null : _updateStatus,
            ),
            const SizedBox(width: 12),
            AppButton(
              label: 'Delete',
              variant: AppButtonVariant.danger,
              icon: Icons.delete_outline_rounded,
              onPressed: _saving ? null : _delete,
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

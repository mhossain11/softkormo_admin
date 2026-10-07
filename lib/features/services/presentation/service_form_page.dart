import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/shell/shell_controller.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/admin_page_header.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/form_section.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/switch_field.dart';
import '../domain/service_item.dart';
import 'service_controller.dart';

/// Create / edit a service (`services` collection).
class ServiceFormPage extends StatefulWidget {
  const ServiceFormPage({super.key, this.service});

  final ServiceItem? service;

  @override
  State<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final ServiceController _controller = getIt<ServiceController>();

  late final TextEditingController _title;
  late final TextEditingController _shortDescription;
  late final TextEditingController _description;
  late final TextEditingController _icon;
  late final TextEditingController _features;
  late final TextEditingController _order;

  late bool _published;

  bool get _editing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _title = TextEditingController(text: service?.title ?? '');
    _shortDescription = TextEditingController(text: service?.shortDescription ?? '');
    _description = TextEditingController(text: service?.description ?? '');
    _icon = TextEditingController(text: service?.icon ?? '');
    _features = TextEditingController(text: service?.features.join('\n') ?? '');
    _order = TextEditingController(
      text: (service?.order ?? _controller.nextOrder).toString(),
    );
    _published = service?.published ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _shortDescription.dispose();
    _description.dispose();
    _icon.dispose();
    _features.dispose();
    _order.dispose();
    super.dispose();
  }

  void _back() => getIt<ShellController>().goBack();

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final current = widget.service;
    final item = ServiceItem(
      id: current?.id ?? '',
      title: _title.text.trim(),
      shortDescription: _shortDescription.text.trim(),
      description: _description.text.trim(),
      icon: _icon.text.trim(),
      features: Validators.splitList(_features.text),
      order: int.tryParse(_order.text) ?? (current?.order ?? _controller.nextOrder),
      published: _published,
      createdAt: current?.createdAt,
      updatedAt: current?.updatedAt,
    );

    final saved = _editing
        ? await _controller.saveItem(item)
        : await _controller.createItem(item);
    if (saved && mounted) _back();
  }

  Future<void> _delete() async {
    final current = widget.service;
    if (current == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete service',
      message: 'Delete "${current.title}"? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    final removed = await _controller.deleteItem(current.id);
    if (removed && mounted) _back();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      scroll: true,
      maxWidth: AppDimensions.formMaxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(
            title: _editing ? 'Edit service' : 'New service',
            subtitle: _editing
                ? 'Update the service shown on the website'
                : 'Add a service to the website catalogue',
            showBack: true,
            onBack: _back,
          ),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: FormSection(
                    title: 'Service details',
                    children: [
                      AppTextField(
                        controller: _title,
                        label: 'Title',
                        required: true,
                        autofocus: !_editing,
                        textCapitalization: TextCapitalization.sentences,
                        hint: 'e.g. Web development',
                      ),
                      AppSpacing.h16,
                      AppTextField(
                        controller: _shortDescription,
                        label: 'Short description',
                        required: true,
                        maxLines: 2,
                        hint: 'One or two lines shown under the title',
                      ),
                      AppSpacing.h16,
                      AppTextField(
                        controller: _description,
                        label: 'Description',
                        maxLines: 5,
                        minLines: 3,
                        hint: 'Full details shown on the service page',
                      ),
                      AppSpacing.h16,
                      AppTextField(
                        controller: _icon,
                        label: 'Icon name',
                        hint: 'Optional Material icon name, e.g. code, cloud, phone_iphone',
                      ),
                    ],
                  ),
                ),
                AppSpacing.h16,
                AppCard(
                  child: FormSection(
                    title: 'Features',
                    description: 'One feature per line or separated by commas.',
                    children: [
                      AppTextField(
                        controller: _features,
                        required: true,
                        maxLines: 6,
                        minLines: 3,
                        hint: 'Responsive design\nSEO friendly\nFast delivery',
                        validator: (value) => Validators.list(value, 'Add at least one feature'),
                      ),
                    ],
                  ),
                ),
                AppSpacing.h16,
                AppCard(
                  child: FormSection(
                    title: 'Visibility',
                    children: [
                      SwitchField(
                        label: 'Published',
                        subtitle: 'Visible on the public website',
                        value: _published,
                        onChanged: (value) => setState(() => _published = value),
                      ),
                      AppSpacing.h16,
                      AppTextField(
                        controller: _order,
                        label: 'Sort order',
                        required: true,
                        keyboardType: TextInputType.number,
                        helper: 'Lower numbers are shown first',
                        validator: (value) => Validators.integer(value, min: 1),
                      ),
                    ],
                  ),
                ),
                AppSpacing.h24,
                Obx(() => FormActions(
                      saving: _controller.saving.value,
                      saveLabel: _editing ? 'Save changes' : 'Create service',
                      onSave: _save,
                      onCancel: _back,
                      deleteAction: _editing ? _delete : null,
                      deleteLabel: 'Delete service',
                    )),
                AppSpacing.h24,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

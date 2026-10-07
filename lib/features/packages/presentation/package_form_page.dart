import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/shell/shell_controller.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/admin_page_header.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/form_section.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/switch_field.dart';
import '../domain/package_plan.dart';
import 'package_controller.dart';

/// Create / edit a pricing package (`packages` collection).
class PackageFormPage extends StatefulWidget {
  const PackageFormPage({super.key, this.package});

  final PackagePlan? package;

  @override
  State<PackageFormPage> createState() => _PackageFormPageState();
}

class _PackageFormPageState extends State<PackageFormPage> {
  static const List<String> _currencies = ['USD', 'EUR', 'GBP', 'BDT', 'INR'];

  final _formKey = GlobalKey<FormState>();
  late final PackageController _controller = getIt<PackageController>();

  late final TextEditingController _name;
  late final TextEditingController _subtitle;
  late final TextEditingController _price;
  late final TextEditingController _billingLabel;
  late final TextEditingController _description;
  late final TextEditingController _features;
  late final TextEditingController _ctaLabel;
  late final TextEditingController _order;

  late String _currency;
  late bool _recommended;
  late bool _active;

  bool get _editing => widget.package != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.package;
    _name = TextEditingController(text: plan?.name ?? '');
    _subtitle = TextEditingController(text: plan?.subtitle ?? '');
    _price = TextEditingController(text: plan == null ? '' : '${plan.price}');
    _billingLabel = TextEditingController(text: plan?.billingLabel ?? 'month');
    _description = TextEditingController(text: plan?.description ?? '');
    _features = TextEditingController(text: plan?.features.join('\n') ?? '');
    _ctaLabel = TextEditingController(text: plan?.ctaLabel ?? 'Get started');
    _order = TextEditingController(
      text: (plan?.order ?? _controller.nextOrder).toString(),
    );
    _currency = _currencies.contains(plan?.currency) ? plan!.currency : 'USD';
    _recommended = plan?.recommended ?? false;
    _active = plan?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    _price.dispose();
    _billingLabel.dispose();
    _description.dispose();
    _features.dispose();
    _ctaLabel.dispose();
    _order.dispose();
    super.dispose();
  }

  void _back() => getIt<ShellController>().goBack();

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final current = widget.package;
    final item = PackagePlan(
      id: current?.id ?? '',
      name: _name.text.trim(),
      subtitle: _subtitle.text.trim(),
      price: num.tryParse(_price.text.trim().replaceAll(',', '')) ?? 0,
      currency: _currency,
      billingLabel: _billingLabel.text.trim(),
      description: _description.text.trim(),
      features: Validators.splitList(_features.text),
      recommended: _recommended,
      active: _active,
      order: int.tryParse(_order.text) ?? (current?.order ?? _controller.nextOrder),
      ctaLabel: _ctaLabel.text.trim(),
      createdAt: current?.createdAt,
      updatedAt: current?.updatedAt,
    );

    final saved = _editing
        ? await _controller.saveItem(item)
        : await _controller.createItem(item);
    if (saved && mounted) _back();
  }

  Future<void> _delete() async {
    final current = widget.package;
    if (current == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete package',
      message: 'Delete "${current.name}"? This cannot be undone.',
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
            title: _editing ? 'Edit package' : 'New package',
            subtitle: _editing
                ? 'Update the pricing plan shown on the website'
                : 'Create a new pricing plan',
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
                    title: 'Plan details',
                    children: [
                      AppTextField(
                        controller: _name,
                        label: 'Name',
                        required: true,
                        autofocus: !_editing,
                        hint: 'e.g. Standard',
                      ),
                      AppSpacing.h16,
                      AppTextField(
                        controller: _subtitle,
                        label: 'Subtitle',
                        hint: 'Short line under the plan name',
                      ),
                      AppSpacing.h16,
                      FormRow(
                        children: [
                          AppTextField(
                            controller: _price,
                            label: 'Price',
                            required: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => Validators.number(value, min: 0),
                          ),
                          AppDropdown<String>(
                            label: 'Currency',
                            value: _currency,
                            items: [
                              for (final currency in _currencies)
                                DropdownItem<String>(value: currency, label: currency),
                            ],
                            onChanged: (value) =>
                                setState(() => _currency = value ?? 'USD'),
                          ),
                        ],
                      ),
                      AppSpacing.h16,
                      AppTextField(
                        controller: _billingLabel,
                        label: 'Billing label',
                        hint: 'e.g. month, project, year',
                      ),
                      AppSpacing.h16,
                      AppTextField(
                        controller: _description,
                        label: 'Description',
                        maxLines: 4,
                        minLines: 2,
                        hint: 'Who is this plan for?',
                      ),
                      AppSpacing.h16,
                      AppTextField(
                        controller: _ctaLabel,
                        label: 'Button label',
                        hint: 'e.g. Get started',
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
                        maxLines: 7,
                        minLines: 3,
                        hint: '5 pages\nContact form\n1 year support',
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
                        label: 'Active',
                        subtitle: 'Shown on the pricing section',
                        value: _active,
                        onChanged: (value) => setState(() => _active = value),
                      ),
                      SwitchField(
                        label: 'Recommended',
                        subtitle: 'Highlighted as the popular plan',
                        value: _recommended,
                        onChanged: (value) => setState(() => _recommended = value),
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
                      saveLabel: _editing ? 'Save changes' : 'Create package',
                      onSave: _save,
                      onCancel: _back,
                      deleteAction: _editing ? _delete : null,
                      deleteLabel: 'Delete package',
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

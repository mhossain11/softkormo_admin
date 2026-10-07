import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/shell/shell_controller.dart';
import '../../../core/data/pending_image.dart';
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
import '../../../core/widgets/image_picker_field.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/switch_field.dart';
import '../domain/testimonial.dart';
import 'testimonial_controller.dart';

/// Create / edit a testimonial (`testimonials` collection) with an optional
/// avatar uploaded to Firebase Storage.
class TestimonialFormPage extends StatefulWidget {
  const TestimonialFormPage({super.key, this.testimonial});

  final Testimonial? testimonial;

  @override
  State<TestimonialFormPage> createState() => _TestimonialFormPageState();
}

class _TestimonialFormPageState extends State<TestimonialFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TestimonialController _controller = getIt<TestimonialController>();

  late final TextEditingController _name;
  late final TextEditingController _designation;
  late final TextEditingController _company;
  late final TextEditingController _message;
  late final TextEditingController _order;

  late int _rating;
  late bool _featured;
  late bool _published;
  PendingImage? _avatar;
  bool _clearedExistingImage = false;

  bool get _editing => widget.testimonial != null;

  String get _existingImage {
    final current = widget.testimonial;
    if (current == null || _clearedExistingImage) return '';
    return current.imageUrl;
  }

  @override
  void initState() {
    super.initState();
    final testimonial = widget.testimonial;
    _name = TextEditingController(text: testimonial?.name ?? '');
    _designation = TextEditingController(text: testimonial?.designation ?? '');
    _company = TextEditingController(text: testimonial?.company ?? '');
    _message = TextEditingController(text: testimonial?.message ?? '');
    _order = TextEditingController(
      text: (testimonial?.order ?? _controller.nextOrder).toString(),
    );
    _rating = testimonial?.rating ?? 5;
    _featured = testimonial?.featured ?? false;
    _published = testimonial?.published ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _designation.dispose();
    _company.dispose();
    _message.dispose();
    _order.dispose();
    super.dispose();
  }

  void _back() => getIt<ShellController>().goBack();

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final current = widget.testimonial;
    final oldImage = current?.imageUrl ?? '';
    final draft = Testimonial(
      id: current?.id ?? '',
      name: _name.text.trim(),
      designation: _designation.text.trim(),
      company: _company.text.trim(),
      message: _message.text.trim(),
      rating: _rating,
      imageUrl: current?.imageUrl ?? '',
      featured: _featured,
      published: _published,
      order: int.tryParse(_order.text) ?? (current?.order ?? _controller.nextOrder),
      createdAt: current?.createdAt,
      updatedAt: current?.updatedAt,
    );

    // The stored image is replaced or removed in this session.
    final dropOldImage =
        oldImage.isNotEmpty && (_avatar != null || _clearedExistingImage);

    final saved = await _controller.saveTestimonial(
      draft,
      avatar: _avatar,
      removedUrl: dropOldImage ? oldImage : null,
    );
    if (saved && mounted) _back();
  }

  Future<void> _delete() async {
    final current = widget.testimonial;
    if (current == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete testimonial',
      message: 'Delete the testimonial from ${current.name}?',
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
            title: _editing ? 'Edit testimonial' : 'New testimonial',
            subtitle: _editing
                ? 'Update the customer feedback shown on the website'
                : 'Add customer feedback to the website',
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
                    title: 'Customer',
                    children: [
                      FormRow(
                        children: [
                          AppTextField(
                            controller: _name,
                            label: 'Name',
                            required: true,
                            autofocus: !_editing,
                            hint: 'Customer name',
                          ),
                          AppTextField(
                            controller: _designation,
                            label: 'Designation',
                            hint: 'e.g. Founder',
                          ),
                        ],
                      ),
                      AppSpacing.h16,
                      FormRow(
                        children: [
                          AppTextField(
                            controller: _company,
                            label: 'Company',
                            hint: 'e.g. Acme Ltd.',
                          ),
                          AppDropdown<int>(
                            label: 'Rating',
                            value: _rating,
                            items: [
                              for (var i = Testimonial.minRating;
                                  i <= Testimonial.maxRating;
                                  i++)
                                DropdownItem<int>(value: i, label: '$i / 5'),
                            ],
                            onChanged: (value) =>
                                setState(() => _rating = value ?? 5),
                          ),
                        ],
                      ),
                      AppSpacing.h16,
                      AppTextField(
                        controller: _message,
                        label: 'Testimonial',
                        required: true,
                        maxLines: 5,
                        minLines: 3,
                        hint: 'What did the customer say?',
                      ),
                    ],
                  ),
                ),
                AppSpacing.h16,
                AppCard(
                  child: FormSection(
                    title: 'Photo',
                    description: 'Optional. Shown next to the testimonial.',
                    children: [
                      ImagePickerField(
                        label: 'Avatar',
                        icon: Icons.account_circle_outlined,
                        value: _existingImage.isEmpty ? null : _existingImage,
                        pending: _avatar,
                        onPicked: (image) => setState(() {
                          _avatar = image;
                          _clearedExistingImage = false;
                        }),
                        onClear: () => setState(() {
                          _avatar = null;
                          _clearedExistingImage = true;
                        }),
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
                      SwitchField(
                        label: 'Featured',
                        subtitle: 'Shown in the highlighted testimonials section',
                        value: _featured,
                        onChanged: (value) => setState(() => _featured = value),
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
                      saveLabel: _editing ? 'Save changes' : 'Create testimonial',
                      onSave: _save,
                      onCancel: _back,
                      deleteAction: _editing ? _delete : null,
                      deleteLabel: 'Delete testimonial',
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

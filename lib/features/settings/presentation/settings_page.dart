import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/pending_image.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/admin_page_header.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_section.dart';
import '../../../core/widgets/image_picker_field.dart';
import '../../../core/widgets/responsive.dart';
import '../domain/site_settings.dart';
import 'settings_controller.dart';

/// Global website settings - single Firestore document `settings/site`.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final SettingsController _controller = getIt<SettingsController>();

  late final TextEditingController _companyName;
  late final TextEditingController _tagline;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _facebook;
  late final TextEditingController _linkedin;
  late final TextEditingController _github;
  late final TextEditingController _youtube;

  PendingImage? _logo;
  String _removedLogo = '';

  SiteSettings get _current => _controller.settings.value ?? SiteSettings.empty();

  @override
  void initState() {
    super.initState();
    final settings = _controller.settings.value;
    _companyName = TextEditingController(text: settings?.companyName ?? '');
    _tagline = TextEditingController(text: settings?.tagline ?? '');
    _email = TextEditingController(text: settings?.email ?? '');
    _phone = TextEditingController(text: settings?.phone ?? '');
    _address = TextEditingController(text: settings?.address ?? '');
    _facebook = TextEditingController(text: settings?.facebook ?? '');
    _linkedin = TextEditingController(text: settings?.linkedin ?? '');
    _github = TextEditingController(text: settings?.github ?? '');
    _youtube = TextEditingController(text: settings?.youtube ?? '');
    _controller.ensureLoaded().then((_) {
      if (!mounted || settings != null) return;
      final loaded = _controller.settings.value;
      if (loaded == null) return;
      setState(() {
        _companyName.text = loaded.companyName;
        _tagline.text = loaded.tagline;
        _email.text = loaded.email;
        _phone.text = loaded.phone;
        _address.text = loaded.address;
        _facebook.text = loaded.facebook;
        _linkedin.text = loaded.linkedin;
        _github.text = loaded.github;
        _youtube.text = loaded.youtube;
      });
    });
  }

  @override
  void dispose() {
    _companyName.dispose();
    _tagline.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _facebook.dispose();
    _linkedin.dispose();
    _github.dispose();
    _youtube.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final current = _current;
    final next = SiteSettings(
      companyName: _companyName.text.trim(),
      tagline: _tagline.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      facebook: _facebook.text.trim(),
      linkedin: _linkedin.text.trim(),
      github: _github.text.trim(),
      youtube: _youtube.text.trim(),
      logoUrl: _removedLogo.isNotEmpty ? '' : current.logoUrl,
      updatedAt: current.updatedAt,
    );

    final saved = await _controller.save(
      next,
      logo: _logo,
      removedLogo: _removedLogo.isEmpty ? null : _removedLogo,
    );
    if (saved && mounted) {
      setState(() {
        _logo = null;
        _removedLogo = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      scroll: true,
      maxWidth: AppDimensions.formMaxWidth,
      child: Obx(() {
        if (_controller.loading.value && !_controller.isLoaded) {
          return const Padding(
            padding: EdgeInsets.only(top: AppSpacing.huge),
            child: LoadingState(message: 'Loading settings...'),
          );
        }
        final error = _controller.errorMessage.value;
        if (error != null && !_controller.isLoaded) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.huge),
            child: ErrorState(message: error, onRetry: _controller.ensureLoaded),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminPageHeader(
              title: 'Site settings',
              subtitle: 'Company details, contact information and social links',
              actions: [
                Obx(() => IconButton(
                      tooltip: 'Reload settings',
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      onPressed: _controller.saving.value
                          ? null
                          : () => _controller.ensureLoaded(force: true),
                    )),
              ],
            ),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: FormSection(
                      title: 'Company',
                      children: [
                        FormRow(
                          children: [
                            AppTextField(
                              controller: _companyName,
                              label: 'Company name',
                              required: true,
                              hint: 'SoftKormo',
                            ),
                            AppTextField(
                              controller: _tagline,
                              label: 'Tagline',
                              hint: 'Short line under the logo',
                            ),
                          ],
                        ),
                        AppSpacing.h16,
                        AppTextField(
                          controller: _address,
                          label: 'Address',
                          hint: 'Street, city, country',
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h16,
                  AppCard(
                    child: FormSection(
                      title: 'Contact',
                      children: [
                        FormRow(
                          children: [
                            AppTextField(
                              controller: _email,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              hint: 'hello@example.com',
                              validator: Validators.email,
                            ),
                            AppTextField(
                              controller: _phone,
                              label: 'Phone',
                              keyboardType: TextInputType.phone,
                              hint: '+880 ...',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h16,
                  AppCard(
                    child: FormSection(
                      title: 'Social links',
                      description: 'Leave a field empty to hide it.',
                      children: [
                        FormRow(
                          children: [
                            AppTextField(
                              controller: _facebook,
                              label: 'Facebook',
                              keyboardType: TextInputType.url,
                              hint: 'https://facebook.com/...',
                              validator: Validators.url,
                            ),
                            AppTextField(
                              controller: _linkedin,
                              label: 'LinkedIn',
                              keyboardType: TextInputType.url,
                              hint: 'https://linkedin.com/...',
                              validator: Validators.url,
                            ),
                          ],
                        ),
                        AppSpacing.h16,
                        FormRow(
                          children: [
                            AppTextField(
                              controller: _github,
                              label: 'GitHub',
                              keyboardType: TextInputType.url,
                              hint: 'https://github.com/...',
                              validator: Validators.url,
                            ),
                            AppTextField(
                              controller: _youtube,
                              label: 'YouTube',
                              keyboardType: TextInputType.url,
                              hint: 'https://youtube.com/...',
                              validator: Validators.url,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h16,
                  AppCard(
                    child: FormSection(
                      title: 'Logo',
                      description: 'Shown in the website header and footer.',
                      children: [
                        ImagePickerField(
                          label: 'Site logo',
                          icon: Icons.image_outlined,
                          value: _current.logoUrl.isEmpty ? null : _current.logoUrl,
                          pending: _logo,
                          onPicked: (image) => setState(() {
                            _logo = image;
                            _removedLogo = '';
                          }),
                          onClear: () => setState(() {
                            _logo = null;
                            _removedLogo = _current.logoUrl;
                          }),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h24,
                  Obx(() => FormActions(
                        saving: _controller.saving.value,
                        saveLabel: 'Save settings',
                        onSave: _save,
                        onCancel: () => _controller.ensureLoaded(force: true),
                      )),
                  AppSpacing.h24,
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

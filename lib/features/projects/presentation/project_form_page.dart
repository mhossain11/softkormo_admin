import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/shell/shell_controller.dart';
import '../../../core/data/pending_image.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/slug.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/admin_page_header.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/form_section.dart';
import '../../../core/widgets/image_picker_field.dart';
import '../../../core/widgets/network_image_view.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/switch_field.dart';
import '../domain/project.dart';
import '../domain/project_input.dart';
import 'project_controller.dart';

/// Create / edit a project: text fields, thumbnail and gallery images.
///
/// Files are staged locally and uploaded only on submit, so cancelling a form
/// never leaves orphaned files in Firebase Storage.
class ProjectFormPage extends StatefulWidget {
  const ProjectFormPage({super.key, this.project});

  final Project? project;

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends State<ProjectFormPage> {
  static const int _maxImageBytes = 8 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final ProjectController _controller = getIt<ProjectController>();

  late final TextEditingController _title;
  late final TextEditingController _slug;
  late final TextEditingController _shortDescription;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _year;
  late final TextEditingController _client;
  late final TextEditingController _technologies;
  late final TextEditingController _githubUrl;
  late final TextEditingController _projectUrl;
  late final TextEditingController _order;

  late bool _featured;
  late bool _published;

  PendingImage? _thumbnail;
  bool _clearedThumbnail = false;
  final List<PendingImage> _stagedGallery = <PendingImage>[];
  late final List<String> _images;
  final List<String> _removedUrls = <String>[];

  bool get _editing => widget.project != null;

  String get _existingThumbnail {
    final current = widget.project;
    if (current == null || _clearedThumbnail) return '';
    return current.thumbnail;
  }

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _title = TextEditingController(text: project?.title ?? '');
    _slug = TextEditingController(text: project?.slug ?? '');
    _shortDescription = TextEditingController(text: project?.shortDescription ?? '');
    _description = TextEditingController(text: project?.description ?? '');
    _category = TextEditingController(text: project?.category ?? '');
    _year = TextEditingController(text: project?.year?.toString() ?? '');
    _client = TextEditingController(text: project?.client ?? '');
    _technologies = TextEditingController(text: project?.technologies.join('\n') ?? '');
    _githubUrl = TextEditingController(text: project?.githubUrl ?? '');
    _projectUrl = TextEditingController(text: project?.projectUrl ?? '');
    _order = TextEditingController(
      text: (project?.order ?? _controller.nextOrder).toString(),
    );
    _featured = project?.featured ?? false;
    _published = project?.published ?? true;
    _images = List<String>.from(project?.images ?? const <String>[]);
  }

  @override
  void dispose() {
    _title.dispose();
    _slug.dispose();
    _shortDescription.dispose();
    _description.dispose();
    _category.dispose();
    _year.dispose();
    _client.dispose();
    _technologies.dispose();
    _githubUrl.dispose();
    _projectUrl.dispose();
    _order.dispose();
    super.dispose();
  }

  void _back() => getIt<ShellController>().goBack();

  Future<void> _pickGallery() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty || !mounted) return;
    var added = 0;
    for (final file in files) {
      final Uint8List bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        AppSnackbar.warning('${file.name} could not be read and was skipped.');
        continue;
      }
      if (bytes.isEmpty) continue;
      if (bytes.length > _maxImageBytes) {
        AppSnackbar.warning('${file.name} is larger than 8 MB and was skipped.');
        continue;
      }
      _stagedGallery.add(PendingImage(bytes: bytes, fileName: file.name));
      added++;
    }
    if (added > 0 && mounted) setState(() {});
  }

  void _removeStaged(int index) {
    setState(() => _stagedGallery.removeAt(index));
  }

  void _removeExisting(String url) {
    setState(() {
      _images.remove(url);
      _removedUrls.add(url);
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_thumbnail == null && _existingThumbnail.isEmpty) {
      AppSnackbar.error('A thumbnail image is required.');
      return;
    }

    final current = widget.project;
    final title = _title.text.trim();
    final slug = _slug.text.trim().isEmpty ? SlugHelper.from(title) : _slug.text.trim();
    final now = DateTime.now();

    final draft = Project(
      id: current?.id ?? '',
      title: title,
      slug: slug,
      shortDescription: _shortDescription.text.trim(),
      description: _description.text.trim(),
      category: _category.text.trim(),
      year: int.tryParse(_year.text.trim()),
      thumbnail: _existingThumbnail,
      images: List<String>.from(_images),
      technologies: Validators.splitList(_technologies.text),
      client: _client.text.trim(),
      githubUrl: _githubUrl.text.trim(),
      projectUrl: _projectUrl.text.trim(),
      featured: _featured,
      published: _published,
      order: int.tryParse(_order.text) ?? (current?.order ?? _controller.nextOrder),
      createdAt: current?.createdAt ?? now,
      updatedAt: current?.updatedAt,
    );

    final saved = await _controller.saveProject(
      ProjectInput(
        project: draft,
        thumbnail: _thumbnail,
        gallery: List<PendingImage>.from(_stagedGallery),
        removedUrls: List<String>.from(_removedUrls),
      ),
    );
    if (saved && mounted) _back();
  }

  Future<void> _delete() async {
    final current = widget.project;
    if (current == null) return;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete project',
      message: 'Delete "${current.title}"? Its images will also be removed from storage.',
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
            title: _editing ? 'Edit project' : 'New project',
            subtitle: _editing
                ? 'Update the portfolio entry shown on the website'
                : 'Add a portfolio entry to the website',
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
                    title: 'Project details',
                    children: [
                      AppTextField(
                        controller: _title,
                        label: 'Title',
                        required: true,
                        autofocus: !_editing,
                        hint: 'e.g. E-commerce platform',
                        onChanged: (value) {
                          // Keep the slug in sync until it is edited by hand.
                          if (_slug.text.isEmpty || SlugHelper.from(value) == _slug.text) {
                            _slug.text = SlugHelper.from(value);
                          }
                        },
                      ),
                      AppSpacing.h16,
                      FormRow(
                        children: [
                          AppTextField(
                            controller: _slug,
                            label: 'Slug',
                            hint: 'generated-from-title',
                            helper: 'Used in the project URL',
                          ),
                          AppTextField(
                            controller: _category,
                            label: 'Category',
                            required: true,
                            hint: 'e.g. Web, Mobile, UI/UX',
                          ),
                        ],
                      ),
                      AppSpacing.h16,
                      AppTextField(
                        controller: _shortDescription,
                        label: 'Short description',
                        required: true,
                        maxLines: 2,
                        hint: 'One or two lines shown in the project list',
                      ),
                      AppSpacing.h16,
                      AppTextField(
                        controller: _description,
                        label: 'Description',
                        maxLines: 6,
                        minLines: 3,
                        hint: 'Full case study text',
                      ),
                      AppSpacing.h16,
                      FormRow(
                        children: [
                          AppTextField(
                            controller: _year,
                            label: 'Year',
                            keyboardType: TextInputType.number,
                            hint: 'e.g. 2026',
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return null;
                              return Validators.integer(text, min: 1990, max: 2100);
                            },
                          ),
                          AppTextField(
                            controller: _client,
                            label: 'Client',
                            hint: 'Optional client name',
                          ),
                        ],
                      ),
                      AppSpacing.h16,
                      AppTextField(
                        controller: _technologies,
                        label: 'Technologies',
                        maxLines: 4,
                        minLines: 2,
                        hint: 'Flutter\nFirebase\nNode.js',
                        helper: 'One technology per line or separated by commas',
                      ),
                    ],
                  ),
                ),
                AppSpacing.h16,
                AppCard(
                  child: FormSection(
                    title: 'Links',
                    description: 'Optional. Shown as buttons on the project page.',
                    children: [
                      FormRow(
                        children: [
                          AppTextField(
                            controller: _githubUrl,
                            label: 'GitHub URL',
                            keyboardType: TextInputType.url,
                            hint: 'https://github.com/...',
                            validator: Validators.url,
                          ),
                          AppTextField(
                            controller: _projectUrl,
                            label: 'Live URL',
                            keyboardType: TextInputType.url,
                            hint: 'https://...',
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
                    title: 'Thumbnail',
                    description: 'Required. Used in project lists and cards.',
                    children: [
                      ImagePickerField(
                        label: 'Thumbnail image',
                        required: true,
                        value: _existingThumbnail.isEmpty ? null : _existingThumbnail,
                        pending: _thumbnail,
                        onPicked: (image) => setState(() {
                          _thumbnail = image;
                          _clearedThumbnail = false;
                        }),
                        onClear: () => setState(() {
                          _thumbnail = null;
                          _clearedThumbnail = true;
                        }),
                      ),
                    ],
                  ),
                ),
                AppSpacing.h16,
                AppCard(
                  child: FormSection(
                    title: 'Gallery',
                    description: 'Extra images for the project detail page.',
                    children: [
                      if (_stagedGallery.isNotEmpty || _images.isNotEmpty) ...[
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: [
                            for (var i = 0; i < _stagedGallery.length; i++)
                              _GalleryTile(
                                key: ValueKey('staged-$i'),
                                child: Image.memory(
                                  _stagedGallery[i].bytes,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                                onRemove: () => _removeStaged(i),
                              ),
                            for (final url in _images)
                              _GalleryTile(
                                key: ValueKey(url),
                                child: NetworkImageView(
                                  url: url,
                                  width: 140,
                                  height: 96,
                                  memCacheWidth: 320,
                                ),
                                onRemove: () => _removeExisting(url),
                              ),
                          ],
                        ),
                        AppSpacing.h16,
                      ],
                      AppButton(
                        label: 'Add images',
                        variant: AppButtonVariant.outline,
                        icon: Icons.add_photo_alternate_outlined,
                        onPressed: _pickGallery,
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
                        subtitle: 'Highlighted on the homepage portfolio section',
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
                      saveLabel: _editing ? 'Save changes' : 'Create project',
                      onSave: _save,
                      onCancel: _back,
                      deleteAction: _editing ? _delete : null,
                      deleteLabel: 'Delete project',
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

/// One gallery image with a remove button.
class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    super.key,
    required this.child,
    required this.onRemove,
  });

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 140,
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: child,
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

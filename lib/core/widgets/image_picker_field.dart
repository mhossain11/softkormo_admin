import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/pending_image.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_snackbar.dart';
import 'network_image_view.dart';

/// Picks one image, shows a preview (existing URL or staged bytes) and never
/// uploads on its own - the form uploads on submit.
class ImagePickerField extends StatelessWidget {
  const ImagePickerField({
    super.key,
    this.label = 'Image',
    this.hint = 'PNG, JPG or WebP',
    this.value,
    this.pending,
    required this.onPicked,
    this.onClear,
    this.uploading = false,
    this.required = false,
    this.maxBytes = 8 * 1024 * 1024,
    this.icon = Icons.image_outlined,
    this.emptyLabel = 'No image selected',
  });

  final String label;
  final String hint;

  /// Currently stored image URL (already in Firebase Storage).
  final String? value;

  /// Image picked in this form session (not uploaded yet).
  final PendingImage? pending;
  final ValueChanged<PendingImage> onPicked;
  final VoidCallback? onClear;
  final bool uploading;
  final bool required;
  final int maxBytes;
  final IconData icon;
  final String emptyLabel;

  Future<void> _pick() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;
    final file = files.first;

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      AppSnackbar.error('The selected file could not be read.');
      return;
    }
    if (bytes.isEmpty) {
      AppSnackbar.error('The selected file could not be read.');
      return;
    }
    if (bytes.length > maxBytes) {
      AppSnackbar.error('Image must be smaller than ${maxBytes ~/ (1024 * 1024)} MB.');
      return;
    }
    onPicked(PendingImage(bytes: bytes, fileName: file.name));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPending = pending != null;
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        AppSpacing.h8,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 132,
              height: 88,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: hasPending
                  ? Image.memory(pending!.bytes, fit: BoxFit.cover, gaplessPlayback: true)
                  : hasValue
                      ? NetworkImageView(url: value!, width: 132, height: 88)
                      : Icon(icon, size: 22, color: scheme.onSurfaceVariant),
            ),
            AppSpacing.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPending
                        ? pending!.fileName
                        : hasValue
                            ? 'Current image'
                            : emptyLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.h8,
                  Text(hint, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  AppSpacing.h12,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppButton(
                        label: hasPending || hasValue ? 'Replace' : 'Choose image',
                        variant: AppButtonVariant.outline,
                        dense: true,
                        icon: Icons.upload_file_rounded,
                        loading: uploading,
                        onPressed: _pick,
                      ),
                      if (hasPending || hasValue)
                        AppButton(
                          label: 'Remove',
                          variant: AppButtonVariant.text,
                          dense: true,
                          icon: Icons.delete_outline_rounded,
                          onPressed: onClear,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

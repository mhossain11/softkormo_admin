import 'dart:typed_data';

/// One image picked in a form but not uploaded yet.
/// Files are uploaded only when the form is submitted, so cancelling a form
/// never leaves orphaned files in Storage.
class PendingImage {
  const PendingImage({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

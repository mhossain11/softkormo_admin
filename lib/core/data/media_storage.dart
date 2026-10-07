import 'dart:typed_data';

import '../services/storage_service.dart';
import '../utils/image_optimizer.dart';

/// Single entry point for Firebase Storage uploads and cleanup.
///
/// Images are optimized before upload, files are stored under a stable
/// directory and removal failures are reported instead of swallowed.
class MediaStorage {
  MediaStorage(this._storage);

  final StorageService _storage;

  /// Optimizes and uploads one image, returning its download URL.
  Future<String> uploadImage({
    required String path,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final optimized = await ImageOptimizer.optimize(bytes, fileName: fileName);
    return _storage.uploadBytes(
      path: path,
      bytes: optimized.bytes,
      contentType: optimized.contentType,
    );
  }

  /// Deletes every file behind [urls] and returns the URLs that could not
  /// be removed, so callers never silently report full success.
  Future<List<String>> deleteUrls(Iterable<String> urls) async {
    final failures = <String>[];
    for (final url in urls.where((u) => u.trim().isNotEmpty)) {
      final path = StoragePath.fromUrl(url);
      if (path == null) continue;
      try {
        await _storage.deleteFile(path);
      } catch (_) {
        failures.add(url);
      }
    }
    return failures;
  }

  /// Filesystem-safe name for an uploaded file.
  static String safeName(String fileName) {
    final lower = fileName.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9.]+'), '-');
    return lower.replaceAll(RegExp(r'-{2,}'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }
}

/// Extracts the Storage object path from a download URL so files can be
/// deleted later without storing extra bookkeeping fields.
class StoragePath {
  const StoragePath._();

  static String? fromUrl(String url) {
    if (url.trim().isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    final index = segments.indexOf('o');
    if (index < 0 || index + 1 >= segments.length) return null;
    final path = segments[index + 1];
    return path.isEmpty ? null : path;
  }
}

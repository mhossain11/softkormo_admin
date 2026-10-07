import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Result of [ImageOptimizer.optimize].
class OptimizedImage {
  const OptimizedImage({required this.bytes, required this.fileName, required this.contentType});

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

/// Down-scales and re-encodes picked images so the admin panel never uploads
/// a full resolution original to Firebase Storage.
class ImageOptimizer {
  const ImageOptimizer._();

  static const int maxDimension = 1600;
  static const int quality = 85;
  static const int skipOptimizationBelowBytes = 120 * 1024;

  static Future<OptimizedImage> optimize(
    Uint8List bytes, {
    required String fileName,
    int targetMaxDimension = maxDimension,
    int targetQuality = quality,
  }) async {
    // Already small files are uploaded untouched.
    if (bytes.length <= skipOptimizationBelowBytes) {
      return OptimizedImage(
        bytes: bytes,
        fileName: _withExtension(fileName),
        contentType: _contentTypeFor(fileName),
      );
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      // Not decodable (e.g. svg or corrupt) - upload as-is.
      return OptimizedImage(bytes: bytes, fileName: fileName, contentType: _contentTypeFor(fileName));
    }

    var image = img.bakeOrientation(decoded);
    if (image.width > targetMaxDimension || image.height > targetMaxDimension) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? targetMaxDimension : null,
        height: image.height > image.width ? targetMaxDimension : null,
      );
    }

    return OptimizedImage(
      bytes: Uint8List.fromList(img.encodeJpg(image, quality: targetQuality)),
      fileName: '${_baseName(fileName)}.jpg',
      contentType: 'image/jpeg',
    );
  }

  static String _baseName(String fileName) {
    final index = fileName.lastIndexOf('.');
    return index > 0 ? fileName.substring(0, index) : fileName;
  }

  static String _withExtension(String fileName) => fileName.contains('.') ? fileName : '$fileName.png';

  static String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.avif')) return 'image/avif';
    return 'image/jpeg';
  }
}

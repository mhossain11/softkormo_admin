import 'dart:typed_data';

import '../../../core/data/media_storage.dart';
import '../../../core/services/firestore_service.dart';
import '../domain/site_settings.dart';

/// Global website settings - one document (`settings/site`) to keep reads low.
class SettingsRepository {
  SettingsRepository(this._firestore, this._media);

  final FirestoreService _firestore;
  final MediaStorage _media;

  Future<SiteSettings> fetch() async {
    final data = await _firestore.getDocument(SiteSettings.path);
    if (data == null) return SiteSettings.empty();
    return SiteSettings.fromMap(data);
  }

  Future<void> save(SiteSettings settings, {DateTime? now}) {
    return _firestore.setDocument(
      SiteSettings.path,
      {...settings.toMap(), 'updatedAt': now ?? DateTime.now()},
    );
  }

  Future<String> uploadLogo({required Uint8List bytes, required String fileName}) {
    return _media.uploadImage(
      path:
          'settings/logo/${DateTime.now().millisecondsSinceEpoch}_${MediaStorage.safeName(fileName)}',
      bytes: bytes,
      fileName: fileName,
    );
  }

  Future<List<String>> removeLogo(String url) => _media.deleteUrls([url]);
}

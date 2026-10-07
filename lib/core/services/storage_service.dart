import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../errors/app_exception.dart';
import '../errors/error_messages.dart';
import 'firebase_service.dart';

/// Firebase Storage file operations (uploads + cleanup).
class StorageService {
  StorageService(this._firebase);

  final FirebaseService _firebase;

  FirebaseStorage get _storage => _firebase.storage;

  /// Uploads [bytes] and returns the public download URL.
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    return guard(() async {
      final reference = _storage.ref(path);
      final task = await reference.putData(
        bytes,
        SettableMetadata(contentType: contentType, cacheControl: 'public, max-age=31536000'),
      );
      return task.ref.getDownloadURL();
    });
  }

  /// Deletes a file. Missing files are treated as success (already gone).
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      throw AppException('Could not remove a stored file.', cause: e);
    } catch (e) {
      throw AppException('Could not remove a stored file.', cause: e);
    }
  }

  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ErrorMessages.asException(e);
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../errors/app_exception.dart';
import '../errors/error_messages.dart';
import 'firebase_service.dart';

/// Generic Cloud Firestore access used by every repository.
///
/// Repositories build queries with [query] / [doc] and execute them through
/// this service, so no feature talks to the Firebase SDK directly.
class FirestoreService {
  FirestoreService(this._firebase);

  final FirebaseService _firebase;

  FirebaseFirestore get _db => _firebase.firestore;

  Query<Map<String, dynamic>> query(String collectionPath) => _db.collection(collectionPath);

  DocumentReference<Map<String, dynamic>> doc(String path) => _db.doc(path);

  Future<Map<String, dynamic>?> getDocument(String path) async {
    return guard(() async {
      final snapshot = await _db.doc(path).get();
      return snapshot.data();
    });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getDocuments(
    Query<Map<String, dynamic>> query,
  ) async {
    return guard(() async {
      final snapshot = await query.get();
      return snapshot.docs;
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> add(
    String collectionPath,
    Map<String, dynamic> data,
  ) {
    return guard(() => _db.collection(collectionPath).add(data));
  }

  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    return guard(() => _db.doc(path).set(data, SetOptions(merge: merge)));
  }

  Future<void> updateDocument(String path, Map<String, dynamic> data) {
    return guard(() => _db.doc(path).update(data));
  }

  Future<void> deleteDocument(String path) {
    return guard(() => _db.doc(path).delete());
  }

  /// Applies several updates in a single commit (used by reorder actions).
  Future<void> updateBatch(Map<String, Map<String, dynamic>> updates) async {
    if (updates.isEmpty) return;
    await guard(() async {
      final batch = _db.batch();
      updates.forEach((path, data) => batch.update(_db.doc(path), data));
      await batch.commit();
    });
  }

  /// Aggregation count - never downloads documents just to count them.
  Future<int> count(Query<Map<String, dynamic>> query) async {
    return guard(() async {
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    });
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

import 'package:cloud_firestore/cloud_firestore.dart';

import '../errors/app_exception.dart';
import '../services/firestore_service.dart';
import 'page_result.dart';

/// Shared implementation of the paginated list queries used by every CMS
/// module. Each feature repository only supplies the collection name, the
/// document parser and its default ordering / search field.
///
/// Query strategy:
/// * default list  -> `orderBy(orderField)` + `limit()` + `startAfterDocument()`
/// * search        -> prefix range on a single text field (no extra reads)
/// * filters       -> equality `where()` (composite indexes declared in
///                    `firestore.indexes.json`)
class ListRepository<T> {
  ListRepository(
    this.firestore, {
    required this.collectionName,
    required this.parse,
    this.orderField = 'order',
    this.orderDescending = false,
    this.searchField = 'title',
  });

  final FirestoreService firestore;
  final String collectionName;
  final T Function(Map<String, dynamic> data, {String id}) parse;
  final String orderField;
  final bool orderDescending;
  final String searchField;

  String pathFor(String id) => '$collectionName/$id';

  Query<Map<String, dynamic>> buildQuery({
    Map<String, Object?> filters = const {},
    String? search,
    int limit = 0,
    DocumentSnapshot<Object?>? after,
  }) {
    var query = firestore.query(collectionName);

    filters.forEach((field, value) {
      if (value != null) query = query.where(field, isEqualTo: value);
    });

    final term = (search ?? '').trim();
    if (term.isNotEmpty) {
      query = query
          .where(searchField, isGreaterThanOrEqualTo: term)
          .where(searchField, isLessThanOrEqualTo: '$term\uf8ff')
          .orderBy(searchField);
    } else {
      query = query.orderBy(orderField, descending: orderDescending);
    }

    if (limit > 0) query = query.limit(limit);
    if (after != null) query = query.startAfterDocument(after);
    return query;
  }

  /// Loads one page using Firestore cursor pagination.
  Future<PageResult<T>> fetchPage({
    Map<String, Object?> filters = const {},
    String? search,
    DocumentSnapshot<Object?>? after,
    int limit = 20,
  }) async {
    final docs = await firestore.getDocuments(
      buildQuery(filters: filters, search: search, limit: limit, after: after),
    );
    return PageResult<T>(
      items: docs.map((doc) => parse(doc.data(), id: doc.id)).toList(),
      cursor: docs.isEmpty ? null : docs.last,
      hasMore: docs.length == limit,
    );
  }

  /// Total matching documents via aggregation - never downloads documents.
  Future<int> count({Map<String, Object?> filters = const {}, String? search}) {
    return firestore.count(buildQuery(filters: filters, search: search));
  }

  Future<T?> getById(String id) async {
    final data = await firestore.getDocument(pathFor(id));
    if (data == null) return null;
    return parse(data, id: id);
  }

  Future<String> create(Map<String, dynamic> data) async {
    final reference = await firestore.add(collectionName, data);
    return reference.id;
  }

  Future<void> update(String id, Map<String, dynamic> data) =>
      firestore.updateDocument(pathFor(id), data);

  Future<void> delete(String id) => firestore.deleteDocument(pathFor(id));

  /// Rewrites `order` for [ids] starting at [offset] + 1 in one batch commit.
  Future<void> reorder(List<String> ids, {int offset = 0, DateTime? now}) async {
    if (ids.isEmpty) return;
    final timestamp = now ?? DateTime.now();
    final updates = <String, Map<String, dynamic>>{};
    for (var i = 0; i < ids.length; i++) {
      updates[pathFor(ids[i])] = {'order': offset + i + 1, 'updatedAt': timestamp};
    }
    await firestore.updateBatch(updates);
  }

  /// Throws an [AppException] when [action] fails with a Firebase error.
  Future<R> guard<R>(Future<R> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('The operation could not be completed.', cause: e);
    }
  }
}

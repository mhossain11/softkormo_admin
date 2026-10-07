import 'package:cloud_firestore/cloud_firestore.dart';

/// One page of results together with the cursor needed for the next query.
class PageResult<T> {
  const PageResult({required this.items, required this.cursor, required this.hasMore});

  final List<T> items;
  final DocumentSnapshot<Object?>? cursor;
  final bool hasMore;

  static const PageResult<Never> empty =
      PageResult(items: [], cursor: null, hasMore: false);
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../data/page_result.dart';
import '../errors/error_messages.dart';

/// Page-based Firestore pagination shared by every list screen.
///
/// Only the current page is kept in memory, the cursor stack allows moving
/// back and forth without re-reading already visited pages, and totals use
/// count aggregation instead of downloading documents.
abstract class PagedController<T> extends GetxController {
  PagedController({this.pageSize = 20});

  final int pageSize;

  final RxList<T> items = <T>[].obs;
  final RxBool loading = false.obs;
  final RxBool hasError = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnInt total = RxnInt();

  /// Start cursors per page index; index 0 is always `null`.
  final List<DocumentSnapshot<Object?>?> _cursors = <DocumentSnapshot<Object?>?>[null];

  int _pageIndex = 0;
  bool _initialized = false;
  bool _requestInFlight = false;

  int get pageIndex => _pageIndex;
  int get currentPage => _pageIndex + 1;
  bool get canGoPrevious => _pageIndex > 0;

  /// Whether a cursor for the next page is known.
  bool get canGoNext => _nextCursorAvailable;
  bool _nextCursorAvailable = false;

  int get totalPages {
    final count = total.value;
    if (count == null || count <= 0) return 1;
    return (count / pageSize).ceil();
  }

  /// Offset of the first row of the current page (used when reordering).
  int get pageOffset => _pageIndex * pageSize;

  /// Implemented by the feature repository.
  Future<PageResult<T>> loadPage({DocumentSnapshot<Object?>? after});

  /// Optional aggregation count. Return `-1` when not supported.
  Future<int> loadTotal() async => -1;

  /// Loads data on first use only - repeated page opens cost no reads.
  Future<void> ensureLoaded() async {
    if (_initialized) return;
    await reload();
  }

  /// Starts over at page 0 with a cleared cursor stack. Used after search,
  /// filter or data changes, where older cursors would no longer be valid.
  Future<void> reload() {
    resetPagination();
    return _goToPage(0);
  }

  Future<void> goToPage(int index) async {
    if (index < 0 || index == _pageIndex) return;
    if (index >= _cursors.length) return; // cursor for that page not known yet
    await _goToPage(index);
  }

  /// Loads the next page when one is known. Never clears the current list.
  Future<void> nextPage() async {
    if (!canGoNext) return;
    await goToPage(_pageIndex + 1);
  }

  Future<void> previousPage() => goToPage(_pageIndex - 1);

  Future<void> _goToPage(int index) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    if (index != 0 || !_initialized) {
      loading.value = true;
    }
    hasError.value = false;
    errorMessage.value = null;
    try {
      final result = await loadPage(after: _cursors[index]);
      items.assignAll(result.items);
      _pageIndex = index;
      _nextCursorAvailable = result.hasMore;
      if (result.cursor != null && _cursors.length == index + 1) {
        _cursors.add(result.cursor);
      }
      _initialized = true;
      await _refreshTotal();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = ErrorMessages.describe(e);
    } finally {
      loading.value = false;
      _requestInFlight = false;
    }
  }

  Future<void> _refreshTotal() async {
    try {
      final value = await loadTotal();
      total.value = value < 0 ? null : value;
    } catch (_) {
      // Aggregation failures must not block the list.
      total.value = null;
    }
  }

  /// Discards the loaded page (used after mutations that change ordering).
  void resetPagination() {
    _cursors..clear()..add(null);
    _pageIndex = 0;
    _nextCursorAvailable = false;
    _initialized = false;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../data/list_repository.dart';
import '../data/page_result.dart';
import 'paged_controller.dart';
import '../errors/error_messages.dart';
import '../utils/debouncer.dart';
import '../widgets/app_snackbar.dart';

/// Base controller for CMS list screens: debounced search, one optional
/// filter (string or boolean), cursor pagination, in-memory patches,
/// deletes and reordering - built on top of [ListRepository].
abstract class CmsListController<T> extends PagedController<T> {
  CmsListController(
    this.repository, {
    super.pageSize,
    this.filterField,
    this.searchDelay = const Duration(milliseconds: 400),
  }) {
    _searchDebouncer = Debouncer(delay: searchDelay, onInput: _applySearch);
  }

  final ListRepository<T> repository;

  /// Firestore field used by the single list filter, e.g. `status`,
  /// `category`, `published`, `active`.
  final String? filterField;
  final Duration searchDelay;

  final RxString search = RxString('');
  final Rxn<Object> filter = Rxn<Object>();
  final RxBool saving = false.obs;

  late final Debouncer _searchDebouncer;

  Map<String, Object?> get activeFilters {
    final field = filterField;
    final value = filter.value;
    if (field == null || value == null) return const {};
    return {field: value};
  }

  bool get hasActiveFilters => filter.value != null || search.value.isNotEmpty;

  @override
  Future<PageResult<T>> loadPage({DocumentSnapshot<Object?>? after}) => repository.fetchPage(
        filters: activeFilters,
        search: search.value,
        after: after,
        limit: pageSize,
      );

  @override
  Future<int> loadTotal() =>
      repository.count(filters: activeFilters, search: search.value);

  void onSearchChanged(String value) => _searchDebouncer(value);

  void _applySearch(String value) {
    final normalized = value.trim();
    if (normalized == search.value) return;
    search.value = normalized;
    reload();
  }

  void setFilter(Object? value) {
    if (filter.value == value) return;
    filter.value = value;
    reload();
  }

  void clearFilters() {
    if (!hasActiveFilters) return;
    filter.value = null;
    search.value = '';
    reload();
  }

  /// Applies [data] on the server and mirrors the change in memory so no
  /// extra read is needed.
  Future<bool> patch(String id, Map<String, dynamic> data) async {
    try {
      await repository.update(id, data);
    } catch (e) {
      AppSnackbar.error(ErrorMessages.describe(e));
      return false;
    }
    final index = items.indexWhere((item) => idOf(item) == id);
    if (index >= 0) {
      items[index] = applyPatch(items[index], data);
      items.refresh();
    }
    return true;
  }

  Future<bool> deleteItem(String id) async {
    saving.value = true;
    try {
      await performDelete(id);
      items.removeWhere((item) => idOf(item) == id);
      final currentTotal = total.value;
      if (currentTotal != null && currentTotal > 0) total.value = currentTotal - 1;
      AppSnackbar.success('$entityLabel deleted');
      return true;
    } catch (e) {
      AppSnackbar.error(ErrorMessages.describe(e));
      return false;
    } finally {
      saving.value = false;
    }
  }

  /// Moves an item one position up/down and rewrites the `order` values of
  /// the current page in a single batch.
  Future<void> moveItem(int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= items.length) return;
    final reordered = List<T>.from(items);
    final moved = reordered.removeAt(index);
    reordered.insert(target, moved);
    try {
      await repository.reorder(
        [for (final item in reordered) idOf(item)],
        offset: pageOffset,
      );
      items.assignAll(reordered);
    } catch (e) {
      AppSnackbar.error(ErrorMessages.describe(e));
    }
  }

  Future<void> performDelete(String id) => repository.delete(id);

  /// Creates a new document (used by simple CMS modules without files).
  Future<bool> createItem(T item) async {
    if (saving.value) return false;
    saving.value = true;
    try {
      final now = DateTime.now();
      await repository.create({...toMapOf(item), 'createdAt': now, 'updatedAt': now});
      AppSnackbar.success('$entityLabel created');
      await reload();
      return true;
    } catch (e) {
      AppSnackbar.error(ErrorMessages.describe(e));
      return false;
    } finally {
      saving.value = false;
    }
  }

  /// Updates an existing document and mirrors it in memory.
  Future<bool> saveItem(T item) async {
    if (saving.value) return false;
    saving.value = true;
    try {
      await repository.update(idOf(item), {...toMapOf(item), 'updatedAt': DateTime.now()});
      upsert(item);
      AppSnackbar.success('$entityLabel updated');
      return true;
    } catch (e) {
      AppSnackbar.error(ErrorMessages.describe(e));
      return false;
    } finally {
      saving.value = false;
    }
  }

  /// Replaces the in-memory copy of [item] when it is on the current page.
  void upsert(T item) {
    final index = items.indexWhere((element) => idOf(element) == idOf(item));
    if (index >= 0) {
      items[index] = item;
      items.refresh();
    }
  }

  /// Order value assigned to newly created documents.
  int get nextOrder {
    var max = 0;
    for (final item in items) {
      final value = orderOf(item);
      if (value > max) max = value;
    }
    return max + 1;
  }

  int orderOf(T item) => 0;

  /// Short label used in success messages.
  String get entityLabel => 'Item';

  /// Re-parses the document with [data] applied (documents stay strongly typed).
  T applyPatch(T item, Map<String, dynamic> data) =>
      repository.parse({...toMapOf(item), ...data}, id: idOf(item));

  String idOf(T item);

  Map<String, dynamic> toMapOf(T item);
}

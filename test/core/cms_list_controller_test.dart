import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softkormoadmin/core/data/list_repository.dart';
import 'package:softkormoadmin/core/data/page_result.dart';
import 'package:softkormoadmin/core/services/firebase_service.dart';
import 'package:softkormoadmin/core/services/firestore_service.dart';
import 'package:softkormoadmin/core/state/cms_list_controller.dart';
import 'package:softkormoadmin/core/utils/map_reader.dart';

/// Minimal strongly typed document used by the fake list module.
class Entry {
  const Entry({
    required this.id,
    required this.name,
    required this.status,
    required this.order,
    this.active = true,
  });

  final String id;
  final String name;
  final String status;
  final int order;
  final bool active;

  factory Entry.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final reader = MapReader(map);
    return Entry(
      id: id,
      name: reader.getString('name'),
      status: reader.getString('status'),
      order: reader.getInt('order'),
      active: reader.getBool('active', true),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status,
        'order': order,
        'active': active,
      };
}

/// In-memory [ListRepository]: applies filters/search locally, records calls
/// and can be told to fail individual operations.
class FakeEntryRepository extends ListRepository<Entry> {
  FakeEntryRepository(this.rows)
      : super(
          FirestoreService(FirebaseService()),
          collectionName: 'entries',
          parse: Entry.fromMap,
          orderField: 'order',
          searchField: 'name',
        );

  List<Entry> rows;

  int fetchCalls = 0;
  int countCalls = 0;
  int updateCalls = 0;
  int createCalls = 0;
  Map<String, Object?> lastFilters = const {};
  String? lastSearch;
  List<String> deletedIds = <String>[];
  List<String>? lastReorderIds;
  int? lastReorderOffset;
  bool failUpdate = false;
  bool failDelete = false;

  List<Entry> _matching(Map<String, Object?> filters, String? search) {
    final term = (search ?? '').trim().toLowerCase();
    return rows.where((row) {
      final data = row.toMap();
      for (final entry in filters.entries) {
        if (data[entry.key] != entry.value) return false;
      }
      if (term.isEmpty) return true;
      return row.name.toLowerCase().startsWith(term);
    }).toList();
  }

  @override
  Future<PageResult<Entry>> fetchPage({
    Map<String, Object?> filters = const {},
    String? search,
    DocumentSnapshot<Object?>? after,
    int limit = 20,
  }) async {
    fetchCalls++;
    lastFilters = filters;
    lastSearch = search;
    final matches = _matching(filters, search);
    return PageResult<Entry>(
      items: matches.take(limit).toList(),
      cursor: null,
      hasMore: false,
    );
  }

  @override
  Future<int> count({Map<String, Object?> filters = const {}, String? search}) async {
    countCalls++;
    return _matching(filters, search).length;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    if (failUpdate) throw StateError('update failed');
    updateCalls++;
    final index = rows.indexWhere((row) => row.id == id);
    if (index < 0) return;
    rows[index] = Entry.fromMap({...rows[index].toMap(), ...data}, id: id);
  }

  @override
  Future<String> create(Map<String, dynamic> data) async {
    createCalls++;
    final id = 'e${createCalls + rows.length}';
    rows.add(Entry.fromMap(data, id: id));
    return id;
  }

  @override
  Future<void> delete(String id) async {
    if (failDelete) throw StateError('delete failed');
    deletedIds.add(id);
    rows.removeWhere((row) => row.id == id);
  }

  @override
  Future<void> reorder(List<String> ids, {int offset = 0, DateTime? now}) async {
    lastReorderIds = ids;
    lastReorderOffset = offset;
  }
}

class EntryListController extends CmsListController<Entry> {
  EntryListController(super.repository, {super.filterField, super.searchDelay});

  @override
  String idOf(Entry item) => item.id;

  @override
  Map<String, dynamic> toMapOf(Entry item) => item.toMap();

  @override
  int orderOf(Entry item) => item.order;

  @override
  String get entityLabel => 'Entry';
}

/// Polls until [condition] holds so debounced timers and async loads are
/// never guessed with a fixed delay - suites run in parallel and a slow
/// machine must not turn a correct implementation into a failure.
Future<void> waitUntil(bool Function() condition, {String? reason}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(reason ?? 'condition was not met within 5 seconds');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  // One extra beat so trailing microtasks (item assignment) settle.
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CmsListController', () {
    late FakeEntryRepository repository;
    late EntryListController controller;

    setUp(() {
      repository = FakeEntryRepository([
        const Entry(id: 'e1', name: 'Alpha', status: 'published', order: 1),
        const Entry(id: 'e2', name: 'Beta', status: 'draft', order: 2),
        const Entry(id: 'e3', name: 'Alpine', status: 'published', order: 3),
      ]);
      controller = EntryListController(
        repository,
        filterField: 'status',
        searchDelay: const Duration(milliseconds: 30),
      );
    });

    test('reload reads the first page without filters', () async {
      await controller.reload();

      expect(controller.items.length, 3);
      expect(controller.currentPage, 1);
      expect(controller.total.value, 3);
      expect(repository.fetchCalls, 1);
      expect(repository.lastFilters, isEmpty);
      expect(repository.lastSearch, isEmpty);
    });

    test('setFilter narrows the query and reloads', () async {
      await controller.reload();

      controller.setFilter('published');
      await waitUntil(() => controller.items.length == 2);

      expect(controller.activeFilters, {'status': 'published'});
      expect(repository.lastFilters['status'], 'published');
      expect(controller.items.map((e) => e.id), ['e1', 'e3']);
      expect(repository.fetchCalls, 2);
    });

    test('selecting the same filter again does not reload', () async {
      await controller.reload();

      controller.setFilter('published');
      await waitUntil(() => controller.items.length == 2);
      final calls = repository.fetchCalls;
      controller.setFilter('published');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(repository.fetchCalls, calls);
    });

    test('search input is debounced into a single query', () async {
      await controller.reload();

      controller
        ..onSearchChanged('a')
        ..onSearchChanged('al')
        ..onSearchChanged('alp');
      await waitUntil(
        () => controller.search.value == 'alp' && controller.items.length == 2,
        reason: 'the debounced search never reached the repository',
      );

      expect(controller.search.value, 'alp');
      expect(repository.lastSearch, 'alp');
      expect(controller.items.map((e) => e.id), ['e1', 'e3']);
      expect(repository.fetchCalls, 2);
    });

    test('clearFilters resets search and filter in one reload', () async {
      await controller.reload();
      controller.setFilter('published');
      await waitUntil(() => controller.items.length == 2);
      controller.onSearchChanged('alp');
      await waitUntil(() => repository.lastSearch == 'alp');
      expect(controller.hasActiveFilters, isTrue);

      final calls = repository.fetchCalls;
      controller.clearFilters();
      await waitUntil(
        () => repository.fetchCalls > calls && repository.lastFilters.isEmpty,
        reason: 'clearing the filters never triggered an unfiltered reload',
      );

      expect(controller.hasActiveFilters, isFalse);
      expect(controller.search.value, '');
      expect(controller.filter.value, isNull);
      expect(repository.lastFilters, isEmpty);
      expect(repository.lastSearch, isEmpty);
      expect(controller.items.length, 3);
    });

    test('patch updates the server and mirrors the change in memory', () async {
      await controller.reload();
      final fetchesBefore = repository.fetchCalls;

      final ok = await controller.patch('e1', {'status': 'archived'});

      expect(ok, isTrue);
      expect(repository.updateCalls, 1);
      final updated = controller.items.firstWhere((e) => e.id == 'e1');
      expect(updated.status, 'archived');
      expect(updated.name, 'Alpha');
      expect(repository.fetchCalls, fetchesBefore, reason: 'a patch costs no extra read');
    });

    test('a failing patch keeps the item untouched', () async {
      await controller.reload();
      repository.failUpdate = true;

      final ok = await controller.patch('e1', {'status': 'archived'});

      expect(ok, isFalse);
      expect(repository.updateCalls, 0);
      final unchanged = controller.items.firstWhere((e) => e.id == 'e1');
      expect(unchanged.status, 'published');
    });

    test('deleteItem removes the row and decrements the total', () async {
      await controller.reload();
      expect(controller.total.value, 3);

      final ok = await controller.deleteItem('e1');

      expect(ok, isTrue);
      expect(repository.deletedIds, ['e1']);
      expect(controller.items.map((e) => e.id), ['e2', 'e3']);
      expect(controller.total.value, 2);
    });

    test('a failing delete keeps the row', () async {
      await controller.reload();
      repository.failDelete = true;

      final ok = await controller.deleteItem('e1');

      expect(ok, isFalse);
      expect(controller.items.length, 3);
      expect(controller.total.value, 3);
      expect(controller.saving.value, isFalse);
    });

    test('moveItem swaps rows and rewrites the page order in one batch', () async {
      await controller.reload();

      await controller.moveItem(0, 1);

      expect(controller.items.map((e) => e.id), ['e2', 'e1', 'e3']);
      expect(repository.lastReorderIds, ['e2', 'e1', 'e3']);
      expect(repository.lastReorderOffset, controller.pageOffset);
    });

    test('moveItem ignores targets outside the page', () async {
      await controller.reload();

      await controller.moveItem(0, -1);
      await controller.moveItem(2, 1);

      expect(repository.lastReorderIds, isNull);
      expect(controller.items.map((e) => e.id), ['e1', 'e2', 'e3']);
    });

    test('nextOrder is the highest order on the page plus one', () async {
      await controller.reload();

      expect(controller.nextOrder, 4);
    });

    test('createItem writes timestamps and refreshes the list', () async {
      await controller.reload();

      final ok = await controller.createItem(
        const Entry(id: '', name: 'Gamma', status: 'draft', order: 4),
      );

      expect(ok, isTrue);
      expect(repository.createCalls, 1);
      final written = repository.rows.last;
      expect(written.name, 'Gamma');
      expect(controller.items.length, 4);
      expect(controller.items.last.name, 'Gamma');
    });

    test('saveItem mirrors the update without an extra read', () async {
      await controller.reload();
      final fetchesBefore = repository.fetchCalls;
      final current = controller.items.firstWhere((e) => e.id == 'e2');
      final renamed = Entry(
        id: current.id,
        name: 'Beta Prime',
        status: current.status,
        order: current.order,
        active: current.active,
      );

      final ok = await controller.saveItem(renamed);

      expect(ok, isTrue);
      expect(repository.updateCalls, 1);
      expect(controller.items.firstWhere((e) => e.id == 'e2').name, 'Beta Prime');
      expect(repository.fetchCalls, fetchesBefore);
    });
  });
}

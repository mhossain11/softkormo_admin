import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softkormoadmin/core/data/page_result.dart';
import 'package:softkormoadmin/core/state/paged_controller.dart';

// DocumentSnapshot is marked sealed by cloud_firestore, so a test double is
// the only way to exercise cursor pagination without a live Firebase project.
// ignore: subtype_of_sealed_class
class FakeCursor implements DocumentSnapshot<Object?> {
  FakeCursor(this.page);

  final int page;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Serves canned pages without touching Firestore.
class TestPagedController extends PagedController<String> {
  TestPagedController(this.pages);

  final List<List<String>> pages;
  final List<Object?> requestedCursors = <Object?>[];

  Completer<void>? hold;
  bool failNextLoad = false;
  bool failTotal = false;
  int totalValue = -1;

  @override
  Future<PageResult<String>> loadPage({DocumentSnapshot<Object?>? after}) async {
    requestedCursors.add(after);
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('offline');
    }
    final gate = hold;
    if (gate != null) await gate.future;

    final page = after == null ? 0 : (after as FakeCursor).page + 1;
    if (page >= pages.length) {
      return PageResult<String>(items: const [], cursor: null, hasMore: false);
    }
    return PageResult<String>(
      items: pages[page],
      cursor: FakeCursor(page),
      hasMore: page + 1 < pages.length,
    );
  }

  @override
  Future<int> loadTotal() async {
    if (failTotal) throw StateError('aggregation unavailable');
    return totalValue;
  }
}

void main() {
  group('PagedController', () {
    late TestPagedController controller;

    setUp(() {
      controller = TestPagedController([
        const ['a1', 'a2'],
        const ['b1', 'b2'],
        const ['c1'],
      ]);
    });

    test('reload loads the first page', () async {
      await controller.reload();

      expect(controller.items, ['a1', 'a2']);
      expect(controller.currentPage, 1);
      expect(controller.pageIndex, 0);
      expect(controller.canGoPrevious, isFalse);
      expect(controller.canGoNext, isTrue);
      expect(controller.loading.value, isFalse);
      expect(controller.hasError.value, isFalse);
      expect(controller.errorMessage.value, isNull);
    });

    test('nextPage and previousPage walk through the loaded cursor stack', () async {
      await controller.reload();
      await controller.nextPage();

      expect(controller.currentPage, 2);
      expect(controller.items, ['b1', 'b2']);
      expect(controller.canGoPrevious, isTrue);
      expect(controller.pageOffset, 20);

      await controller.previousPage();

      expect(controller.currentPage, 1);
      expect(controller.items, ['a1', 'a2']);
      expect(controller.canGoPrevious, isFalse);
    });

    test('the last page reports no further pages', () async {
      await controller.reload();
      await controller.nextPage();
      await controller.nextPage();

      expect(controller.items, ['c1']);
      expect(controller.currentPage, 3);
      expect(controller.canGoNext, isFalse);

      await controller.nextPage();
      expect(controller.currentPage, 3);
      expect(controller.items, ['c1']);
    });

    test('goToPage ignores pages without a known cursor', () async {
      await controller.reload();
      final loads = controller.requestedCursors.length;

      await controller.goToPage(5);

      expect(controller.currentPage, 1);
      expect(controller.requestedCursors.length, loads);
    });

    test('reload clears the cursor stack after a page change', () async {
      await controller.reload();
      await controller.nextPage();
      expect(controller.currentPage, 2);

      await controller.reload();

      expect(controller.currentPage, 1);
      expect(controller.canGoPrevious, isFalse);
      expect(controller.requestedCursors.last, isNull);
    });

    test('ensureLoaded only reads the first page once', () async {
      await controller.ensureLoaded();
      await controller.ensureLoaded();
      await controller.ensureLoaded();

      expect(controller.requestedCursors.length, 1);
    });

    test('totalPages is derived from the aggregation count', () async {
      controller.totalValue = 45;
      await controller.reload();
      expect(controller.total.value, 45);
      expect(controller.totalPages, 3);

      controller.totalValue = 21;
      await controller.reload();
      expect(controller.totalPages, 2);

      controller.totalValue = -1;
      await controller.reload();
      expect(controller.total.value, isNull);
      expect(controller.totalPages, 1);
    });

    test('a failing count does not break the list', () async {
      controller.failTotal = true;
      await controller.reload();

      expect(controller.items, ['a1', 'a2']);
      expect(controller.total.value, isNull);
      expect(controller.hasError.value, isFalse);
    });

    test('a failing page surfaces a friendly error and recovers', () async {
      controller.failNextLoad = true;
      await controller.reload();

      expect(controller.hasError.value, isTrue);
      expect(controller.errorMessage.value, 'Something went wrong. Please try again.');
      expect(controller.loading.value, isFalse);
      expect(controller.items, isEmpty);

      await controller.reload();

      expect(controller.hasError.value, isFalse);
      expect(controller.errorMessage.value, isNull);
      expect(controller.items, ['a1', 'a2']);
    });

    test('reports loading only while a page is in flight', () async {
      final gate = Completer<void>();
      controller.hold = gate;

      final pending = controller.reload();
      expect(controller.loading.value, isTrue);
      expect(controller.items, isEmpty);

      gate.complete();
      await pending;

      expect(controller.loading.value, isFalse);
      expect(controller.items, ['a1', 'a2']);
    });
  });
}

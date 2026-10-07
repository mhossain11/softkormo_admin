import 'package:flutter_test/flutter_test.dart';
import 'package:softkormoadmin/core/data/list_repository.dart';
import 'package:softkormoadmin/core/errors/app_exception.dart';
import 'package:softkormoadmin/core/services/firebase_service.dart';
import 'package:softkormoadmin/core/services/firestore_service.dart';

/// Records the batch written by [ListRepository.reorder] without Firestore.
class RecordingFirestoreService extends FirestoreService {
  RecordingFirestoreService() : super(FirebaseService());

  Map<String, Map<String, dynamic>>? lastBatch;
  int batchCalls = 0;

  @override
  Future<void> updateBatch(Map<String, Map<String, dynamic>> updates) async {
    batchCalls++;
    lastBatch = updates;
  }
}

Map<String, dynamic> _passthrough(Map<String, dynamic> data, {String id = ''}) => data;

void main() {
  group('ListRepository', () {
    late RecordingFirestoreService firestore;
    late ListRepository<Map<String, dynamic>> repository;

    setUp(() {
      firestore = RecordingFirestoreService();
      repository = ListRepository<Map<String, dynamic>>(
        firestore,
        collectionName: 'services',
        parse: _passthrough,
        orderField: 'order',
        searchField: 'title',
      );
    });

    test('pathFor builds document paths', () {
      expect(repository.pathFor('s1'), 'services/s1');
    });

    test('reorder rewrites orders relative to the page offset in one batch', () async {
      await repository.reorder(['s3', 's1', 's2'], offset: 20);

      expect(firestore.batchCalls, 1);
      expect(firestore.lastBatch!.keys, ['services/s3', 'services/s1', 'services/s2']);
      expect(firestore.lastBatch!['services/s3']!['order'], 21);
      expect(firestore.lastBatch!['services/s1']!['order'], 22);
      expect(firestore.lastBatch!['services/s2']!['order'], 23);
      expect(firestore.lastBatch!['services/s3']!['updatedAt'], isA<DateTime>());
    });

    test('reorder with an empty list writes nothing', () async {
      await repository.reorder(const []);

      expect(firestore.batchCalls, 0);
      expect(firestore.lastBatch, isNull);
    });

    test('guard passes successful values through', () async {
      expect(await repository.guard(() async => 42), 42);
    });

    test('guard rethrows AppExceptions unchanged', () async {
      const original = AppException('Not allowed.', cause: 'reason');

      await expectLater(
        repository.guard<void>(() async => throw original),
        throwsA(same(original)),
      );
    });

    test('guard wraps unknown errors with a safe message', () async {
      await expectLater(
        repository.guard<void>(() async => throw StateError('boom')),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            'The operation could not be completed.',
          ),
        ),
      );
    });
  });
}

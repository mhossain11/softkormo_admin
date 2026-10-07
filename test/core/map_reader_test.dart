import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softkormoadmin/core/utils/map_reader.dart';

void main() {
  group('MapReader', () {
    test('getString returns strings, stringifies other types and falls back', () {
      const reader = MapReader({'name': 'SoftKormo', 'count': 42, 'missing': null});
      expect(reader.getString('name'), 'SoftKormo');
      expect(reader.getString('count'), '42');
      expect(reader.getString('missing'), '');
      expect(reader.getString('missing', 'n/a'), 'n/a');
    });

    test('getStringOrNull turns blank and missing values into null', () {
      const reader = MapReader({'blank': '   ', 'value': 'text', 'none': null});
      expect(reader.getStringOrNull('blank'), isNull);
      expect(reader.getStringOrNull('value'), 'text');
      expect(reader.getStringOrNull('none'), isNull);
      expect(reader.getStringOrNull('missing'), isNull);
    });

    test('getBool accepts booleans, strings and numbers', () {
      const reader = MapReader({
        'yes': true,
        'no': false,
        'strTrue': 'true',
        'strFalse': 'FALSE',
        'numOne': 1,
        'numZero': 0,
        'broken': Object,
      });
      expect(reader.getBool('yes'), isTrue);
      expect(reader.getBool('no'), isFalse);
      expect(reader.getBool('strTrue'), isTrue);
      expect(reader.getBool('strFalse'), isFalse);
      expect(reader.getBool('numOne'), isTrue);
      expect(reader.getBool('numZero'), isFalse);
      expect(reader.getBool('broken'), isFalse);
      expect(reader.getBool('missing', true), isTrue);
    });

    test('getInt accepts ints, rounded numbers and numeric strings', () {
      const reader = MapReader({'i': 7, 'd': 4.6, 's': '12', 'bad': 'twelve'});
      expect(reader.getInt('i'), 7);
      expect(reader.getInt('d'), 5);
      expect(reader.getInt('s'), 12);
      expect(reader.getInt('bad'), 0);
      expect(reader.getInt('bad', 3), 3);
      expect(reader.getInt('missing'), 0);
    });

    test('getIntOrNull returns null for missing or unusable values', () {
      const reader = MapReader({'i': 7, 'd': 4.6, 's': '12', 'bad': 'twelve'});
      expect(reader.getIntOrNull('i'), 7);
      expect(reader.getIntOrNull('d'), 5);
      expect(reader.getIntOrNull('s'), 12);
      expect(reader.getIntOrNull('bad'), isNull);
      expect(reader.getIntOrNull('missing'), isNull);
    });

    test('getDouble and getNum strip thousand separators', () {
      const reader = MapReader({'price': '1,250.75', 'plain': 9, 'broken': 'abc'});
      expect(reader.getDouble('price'), 1250.75);
      expect(reader.getDouble('plain'), 9);
      expect(reader.getDouble('broken'), 0);
      expect(reader.getNum('price'), 1250.75);
      expect(reader.getNum('plain'), 9);
      expect(reader.getNum('broken'), 0);
    });

    test('getStringList normalizes lists and single strings', () {
      const reader = MapReader({
        'list': ['Flutter', 42, '  ', 'Firebase'],
        'single': 'Dart',
        'csv': 'Flutter, Firebase',
        'blank': '   ',
        'broken': 7,
      });
      expect(reader.getStringList('list'), ['Flutter', '42', 'Firebase']);
      expect(reader.getStringList('single'), ['Dart']);
      expect(reader.getStringList('csv'), ['Flutter', 'Firebase']);
      expect(reader.getStringList('blank'), isEmpty);
      expect(reader.getStringList('broken'), isEmpty);
      expect(reader.getStringList('missing'), isEmpty);
    });

    test('getDate supports timestamps, dates, epochs and ISO strings', () {
      final timestamp = Timestamp.fromDate(DateTime(2024, 1, 2, 3, 4, 5));
      final reader = MapReader({
        'timestamp': timestamp,
        'date': DateTime(2024, 3, 4),
        'epoch': 1704067200000,
        'iso': '2024-05-06T07:08:09.000Z',
        'broken': Object(),
      });
      expect(
        reader.getDate('timestamp')!.millisecondsSinceEpoch,
        timestamp.millisecondsSinceEpoch,
      );
      expect(
        reader.getDate('date')!.millisecondsSinceEpoch,
        DateTime(2024, 3, 4).millisecondsSinceEpoch,
      );
      expect(
        reader.getDate('epoch')!.millisecondsSinceEpoch,
        1704067200000,
      );
      expect(
        reader.getDate('iso')!.millisecondsSinceEpoch,
        DateTime.parse('2024-05-06T07:08:09.000Z').millisecondsSinceEpoch,
      );
      expect(reader.getDate('broken'), isNull);
      expect(reader.getDate('missing'), isNull);
    });
  });
}

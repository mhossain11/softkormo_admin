import 'package:cloud_firestore/cloud_firestore.dart';

import 'validators.dart';

/// Safe reader for `Map<String, dynamic>` documents coming from Firestore.
/// Every model uses it so missing or wrongly typed fields never crash.
class MapReader {
  const MapReader(this.map);

  final Map<String, dynamic> map;

  String getString(String key, [String fallback = '']) {
    final value = map[key];
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  String? getStringOrNull(String key) {
    final value = map[key];
    if (value == null) return null;
    final text = value is String ? value : value.toString();
    return text.trim().isEmpty ? null : text;
  }

  bool getBool(String key, [bool fallback = false]) {
    final value = map[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return fallback;
  }

  int getInt(String key, [int fallback = 0]) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  int? getIntOrNull(String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double getDouble(String key, [double fallback = 0]) {
    final value = map[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? fallback;
    return fallback;
  }

  /// Accepts numbers as well as numeric strings (legacy website data).
  num getNum(String key, [num fallback = 0]) {
    final value = map[key];
    if (value is num) return value;
    if (value is String) return num.tryParse(value.replaceAll(',', '')) ?? fallback;
    return fallback;
  }

  List<String> getStringList(String key) {
    final value = map[key];
    if (value is List) {
      return value.whereType<Object>().map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    // Legacy documents keep comma or newline separated values in one string;
    // splitting matches how the CMS forms write lists.
    if (value is String) return Validators.splitList(value);
    return const [];
  }

  List<String> getStringListOrNull(String key) {
    final list = getStringList(key);
    return list.isEmpty ? const [] : list;
  }

  DateTime? getDate(String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

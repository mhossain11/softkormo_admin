import '../../../core/services/firestore_service.dart';
import '../../contacts/domain/contact.dart';
import '../domain/dashboard_stats.dart';

/// Dashboard reads - every section uses count aggregation or `limit()` so the
/// dashboard stays fast and cheap on reads.
class DashboardRepository {
  DashboardRepository(this._firestore);

  final FirestoreService _firestore;

  Future<DashboardStats> fetchStats() async {
    final contacts = _firestore.query(Contact.collection);
    final results = await Future.wait<int>([
      _firestore.count(contacts),
      _firestore.count(contacts.where('status', isEqualTo: 'new')),
      _firestore.count(_firestore.query('projects')),
      _firestore.count(_firestore.query('services')),
      _firestore.count(_firestore.query('packages')),
      _firestore.count(_firestore.query('testimonials')),
    ]);
    return DashboardStats(
      totalContacts: results[0],
      newContacts: results[1],
      projects: results[2],
      services: results[3],
      packages: results[4],
      testimonials: results[5],
    );
  }

  Future<List<Contact>> fetchRecentContacts({int limit = 6}) async {
    final docs = await _firestore.getDocuments(
      _firestore.query(Contact.collection).orderBy('createdAt', descending: true).limit(limit),
    );
    return docs.map((doc) => Contact.fromMap(doc.data(), id: doc.id)).toList();
  }

  /// Contacts received per month for the last [months] months (one count
  /// query per month - no documents are downloaded).
  Future<List<LabelCount>> fetchMonthlyContacts({int months = 6}) async {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final ranges = <(String, DateTime, DateTime)>[];
    for (var i = months - 1; i >= 0; i--) {
      final start = DateTime(firstOfMonth.year, firstOfMonth.month - i, 1);
      final end = DateTime(start.year, start.month + 1, 1);
      ranges.add((
        _monthLabel(start),
        start,
        end,
      ));
    }

    final counts = await Future.wait<int>(ranges.map((range) {
      return _firestore.count(
        _firestore
            .query(Contact.collection)
            .where('createdAt', isGreaterThanOrEqualTo: range.$2, isLessThan: range.$3),
      );
    }));

    return [
      for (var i = 0; i < ranges.length; i++)
        LabelCount(label: ranges[i].$1, count: counts[i]),
    ];
  }

  /// Contact pipeline breakdown for the pie chart.
  Future<List<LabelCount>> fetchStatusCounts() async {
    final contacts = _firestore.query(Contact.collection);
    final counts = await Future.wait<int>(
      Contact.statuses.map((status) => _firestore.count(contacts.where('status', isEqualTo: status))),
    );
    return [
      for (var i = 0; i < Contact.statuses.length; i++)
        LabelCount(label: Contact.statuses[i], count: counts[i]),
    ];
  }

  static String _monthLabel(DateTime date) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[date.month - 1];
  }
}

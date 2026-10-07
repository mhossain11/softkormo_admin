import '../../../core/data/list_repository.dart';
import '../domain/contact.dart';

/// Leads submitted by the public website contact form.
///
/// Default list query: `orderBy(createdAt, descending: true)` with cursor
/// pagination so the panel never downloads the whole collection.
class ContactRepository extends ListRepository<Contact> {
  ContactRepository(super.firestore)
      : super(
          collectionName: Contact.collection,
          parse: Contact.fromMap,
          orderField: 'createdAt',
          orderDescending: true,
          searchField: 'name',
        );

  Future<void> updateStatus(String id, String status) => update(id, {'status': status});

  Future<List<Contact>> fetchRecentContacts({int limit = 6}) async {
    final docs = await firestore.getDocuments(
      firestore.query(collectionName).orderBy('createdAt', descending: true).limit(limit),
    );
    return docs.map((doc) => parse(doc.data(), id: doc.id)).toList();
  }
}

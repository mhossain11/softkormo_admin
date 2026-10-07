import '../../../core/errors/error_messages.dart';
import '../../../core/state/cms_list_controller.dart';
import '../domain/contact.dart';

/// Contact inbox: search, status filter, pagination, status updates, delete.
class ContactController extends CmsListController<Contact> {
  ContactController(super.repository) : super(filterField: 'status');

  @override
  String get entityLabel => 'Contact';

  @override
  String idOf(Contact item) => item.id;

  @override
  Map<String, dynamic> toMapOf(Contact item) => item.toMap();

  Future<bool> updateStatus(Contact contact, String status) =>
      patch(contact.id, {'status': status});

  String? get statusFilter {
    final value = filter.value;
    if (value is String && availableStatuses.contains(value)) return value;
    return null;
  }

  /// Filter options shown in the toolbar.
  List<String> get availableStatuses => Contact.statuses;

  String friendlyError(Object error) => ErrorMessages.describe(error);
}

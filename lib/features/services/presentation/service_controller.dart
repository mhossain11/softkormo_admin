import '../../../core/state/cms_list_controller.dart';
import '../domain/service_item.dart';

/// Services CMS: create, edit, publish toggle and reorder.
class ServiceController extends CmsListController<ServiceItem> {
  ServiceController(super.repository) : super(filterField: 'published');

  @override
  String get entityLabel => 'Service';

  @override
  String idOf(ServiceItem item) => item.id;

  @override
  Map<String, dynamic> toMapOf(ServiceItem item) => item.toMap();

  @override
  int orderOf(ServiceItem item) => item.order;

  Future<bool> togglePublished(ServiceItem item) =>
      patch(item.id, {'published': !item.published});
}

import '../../../core/data/list_repository.dart';
import '../domain/service_item.dart';

/// Service offerings (`services` collection).
class ServiceRepository extends ListRepository<ServiceItem> {
  ServiceRepository(super.firestore)
      : super(
          collectionName: ServiceItem.collection,
          parse: ServiceItem.fromMap,
          orderField: 'order',
          searchField: 'title',
        );
}

import '../../../core/data/list_repository.dart';
import '../domain/package_plan.dart';

/// Pricing packages (`packages` collection). Nothing is hardcoded - the admin
/// can create any number of packages.
class PackageRepository extends ListRepository<PackagePlan> {
  PackageRepository(super.firestore)
      : super(
          collectionName: PackagePlan.collection,
          parse: PackagePlan.fromMap,
          orderField: 'order',
          searchField: 'name',
        );
}

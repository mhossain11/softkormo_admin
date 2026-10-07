import '../../../core/state/cms_list_controller.dart';
import '../domain/package_plan.dart';

/// Packages CMS: any number of plans, activate/deactivate, recommended flag.
class PackageController extends CmsListController<PackagePlan> {
  PackageController(super.repository) : super(filterField: 'active');

  @override
  String get entityLabel => 'Package';

  @override
  String idOf(PackagePlan item) => item.id;

  @override
  Map<String, dynamic> toMapOf(PackagePlan item) => item.toMap();

  @override
  int orderOf(PackagePlan item) => item.order;

  Future<bool> toggleActive(PackagePlan item) =>
      patch(item.id, {'active': !item.active});

  Future<bool> toggleRecommended(PackagePlan item) =>
      patch(item.id, {'recommended': !item.recommended});
}

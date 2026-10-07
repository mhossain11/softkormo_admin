import 'package:get/get.dart';

import '../../../core/errors/error_messages.dart';
import '../../contacts/domain/contact.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_stats.dart';

/// Dashboard data. Every section loads and fails independently so one slow
/// query never blocks the whole page.
class DashboardController extends GetxController {
  DashboardController(this._repository);

  final DashboardRepository _repository;

  final Rxn<DashboardStats> stats = Rxn<DashboardStats>();
  final RxBool statsLoading = false.obs;
  final RxnString statsError = RxnString();

  final RxList<Contact> recentContacts = <Contact>[].obs;
  final RxBool recentLoading = false.obs;
  final RxnString recentError = RxnString();

  final RxList<LabelCount> monthlyContacts = <LabelCount>[].obs;
  final RxList<LabelCount> statusCounts = <LabelCount>[].obs;
  final RxBool chartsLoading = false.obs;
  final RxnString chartsError = RxnString();

  void loadAll() {
    loadStats();
    loadRecentContacts();
    loadCharts();
  }

  Future<void> loadStats() async {
    statsLoading.value = true;
    statsError.value = null;
    try {
      stats.value = await _repository.fetchStats();
    } catch (e) {
      statsError.value = ErrorMessages.describe(e);
    } finally {
      statsLoading.value = false;
    }
  }

  Future<void> loadRecentContacts() async {
    recentLoading.value = true;
    recentError.value = null;
    try {
      recentContacts.assignAll(await _repository.fetchRecentContacts(limit: 6));
    } catch (e) {
      recentError.value = ErrorMessages.describe(e);
    } finally {
      recentLoading.value = false;
    }
  }

  Future<void> loadCharts() async {
    chartsLoading.value = true;
    chartsError.value = null;
    try {
      final results = await Future.wait([
        _repository.fetchMonthlyContacts(),
        _repository.fetchStatusCounts(),
      ]);
      monthlyContacts.assignAll(results[0]);
      statusCounts.assignAll(results[1]);
    } catch (e) {
      chartsError.value = ErrorMessages.describe(e);
    } finally {
      chartsLoading.value = false;
    }
  }
}

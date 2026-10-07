import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';

/// Navigation state of the admin shell.
///
/// The shell lives in a single root route; pages are swapped inside its own
/// [Navigator], so the sidebar/header are never rebuilt on navigation and
/// loaded data stays in memory.
class ShellController extends GetxController {
  ShellController() {
    navigatorKey = GlobalKey<NavigatorState>();
    scaffoldKey = GlobalKey<ScaffoldState>();
  }

  late final GlobalKey<NavigatorState> navigatorKey;
  late final GlobalKey<ScaffoldState> scaffoldKey;

  final RxString currentRoute = Routes.dashboard.obs;

  /// Desktop only: user controlled sidebar collapse.
  final RxBool sidebarCollapsed = false.obs;

  void toggleSidebar() => sidebarCollapsed.value = !sidebarCollapsed.value;

  static const Map<String, String> titles = {
    Routes.dashboard: 'Dashboard',
    Routes.contacts: 'Contacts',
    Routes.projects: 'Projects',
    Routes.projectNew: 'New Project',
    Routes.projectEdit: 'Edit Project',
    Routes.services: 'Services',
    Routes.serviceNew: 'New Service',
    Routes.serviceEdit: 'Edit Service',
    Routes.packages: 'Packages',
    Routes.packageNew: 'New Package',
    Routes.packageEdit: 'Edit Package',
    Routes.testimonials: 'Testimonials',
    Routes.testimonialNew: 'New Testimonial',
    Routes.testimonialEdit: 'Edit Testimonial',
    Routes.settings: 'Settings',
  };

  String get currentTitle => titles[currentRoute.value] ?? 'Dashboard';

  /// Sidebar navigation: keeps the stack shallow (dashboard + current page).
  void openPage(String route) {
    closeDrawer();
    if (currentRoute.value == route) return;
    navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (r) => r.isFirst);
  }

  /// Opens a page on top of the current one (forms, details).
  void pushPage(String route, {Object? arguments}) {
    closeDrawer();
    navigatorKey.currentState?.pushNamed(route, arguments: arguments);
  }

  void goBack() {
    final state = navigatorKey.currentState;
    if (state != null && state.canPop()) state.pop();
  }

  void closeDrawer() {
    final state = scaffoldKey.currentState;
    if (state?.isDrawerOpen ?? false) state?.closeDrawer();
  }

  void onRouteChanged(String? name) {
    if (name == null || name.isEmpty) return;
    currentRoute.value = name;
  }

  bool isActive(String route) {
    if (route == Routes.contacts) return currentRoute.value.startsWith(Routes.contacts);
    if (route == Routes.projects) return currentRoute.value.startsWith(Routes.projects);
    if (route == Routes.services) return currentRoute.value.startsWith(Routes.services);
    if (route == Routes.packages) return currentRoute.value.startsWith(Routes.packages);
    if (route == Routes.testimonials) return currentRoute.value.startsWith(Routes.testimonials);
    return currentRoute.value == route;
  }
}

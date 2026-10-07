import 'package:flutter/widgets.dart';

import 'shell_controller.dart';

/// Keeps [ShellController.currentRoute] in sync with the shell navigator so
/// the sidebar and header only rebuild when the active page changes.
class ShellRouteObserver extends NavigatorObserver {
  ShellRouteObserver(this.controller);

  final ShellController controller;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller.onRouteChanged(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller.onRouteChanged(previousRoute?.settings.name);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller.onRouteChanged(previousRoute?.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    controller.onRouteChanged(newRoute?.settings.name);
  }
}

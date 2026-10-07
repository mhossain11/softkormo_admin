import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/di/injection.dart';
import '../presentation/auth_controller.dart';

/// Keeps unauthenticated visitors out of the admin area.
class EnsureAuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final controller = getIt<AuthController>();
    if (controller.isAuthenticated || controller.hasFirebaseSession) return null;
    return const RouteSettings(name: Routes.login);
  }
}

/// Sends already signed-in admins from the login page to the dashboard.
class GuestMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final controller = getIt<AuthController>();
    if (controller.isAuthenticated) return const RouteSettings(name: Routes.admin);
    return null;
  }
}

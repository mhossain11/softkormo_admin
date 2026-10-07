import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/di/injection.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/admin_shell.dart';
import '../features/auth/presentation/auth_middleware.dart';
import '../features/auth/presentation/login_page.dart';
import 'routes/app_routes.dart';
import 'theme_controller.dart';

/// Root widget of the admin panel.
///
/// Two root routes only:
/// * `/login` - guarded by [GuestMiddleware]
/// * `/admin` - guarded by [EnsureAuthMiddleware]; hosts its own nested
///   navigator, so the shell (sidebar/header) is built once per session.
class SoftKormoAdmin extends StatelessWidget {
  const SoftKormoAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = getIt<ThemeController>();
    return GetMaterialApp(
      title: 'SoftKormo Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeController.themeMode,
      initialRoute: Routes.login,
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 120),
      getPages: [
        GetPage(
          name: Routes.login,
          page: () => const LoginPage(),
          middlewares: [GuestMiddleware()],
        ),
        GetPage(
          name: Routes.admin,
          page: () => const AdminShell(),
          middlewares: [EnsureAuthMiddleware()],
        ),
      ],
    );
  }
}

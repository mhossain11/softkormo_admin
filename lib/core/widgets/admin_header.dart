import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/shell/shell_controller.dart';
import '../../app/theme_controller.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/presentation/auth_controller.dart';
import 'app_button.dart';

/// Top bar: navigation toggle, current page title and account actions.
class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = getIt<ShellController>();
    final themeController = getIt<ThemeController>();
    final auth = getIt<AuthController>();
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Container(
      height: AppDimensions.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (isMobile)
            AppIconButton(
              icon: Icons.menu_rounded,
              tooltip: 'Open menu',
              onPressed: () => shell.scaffoldKey.currentState?.openDrawer(),
            )
          else
            Obx(
              () => AppIconButton(
                icon: shell.sidebarCollapsed.value
                    ? Icons.menu_open_rounded
                    : Icons.menu_rounded,
                tooltip: shell.sidebarCollapsed.value ? 'Expand sidebar' : 'Collapse sidebar',
                onPressed: shell.toggleSidebar,
              ),
            ),
          if (!isMobile) AppSpacing.w8,
          Expanded(
            child: Obx(
              () => Text(
                shell.currentTitle,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          Obx(
            () => AppIconButton(
              icon: themeController.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              tooltip: themeController.isDark ? 'Use light theme' : 'Use dark theme',
              onPressed: themeController.toggleLightDark,
            ),
          ),
          AppSpacing.w8,
          Obx(() {
            final admin = auth.admin.value;
            return PopupMenuButton<String>(
              tooltip: 'Account',
              onSelected: (value) {
                if (value == 'settings') {
                  shell.openPage(Routes.settings);
                } else if (value == 'logout') {
                  auth.signOut();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    admin == null ? 'Admin' : '${admin.name} · ${admin.role}',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                const PopupMenuItem(value: 'settings', child: Text('Settings')),
                const PopupMenuItem(value: 'logout', child: Text('Sign out')),
              ],
              child: CircleAvatar(
                radius: 15,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  (admin?.name.isEmpty ?? true) ? 'A' : admin!.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

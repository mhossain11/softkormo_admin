import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/shell/shell_controller.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'app_button.dart';

class _NavItem {
  const _NavItem(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}

/// Navigation rail / drawer content.
///
/// Rebuild scope is limited to the active item (via [Obx]); the rest of the
/// shell is untouched while navigating.
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key, this.collapsed = false, this.inDrawer = false});

  final bool collapsed;

  /// True when rendered inside the mobile drawer.
  final bool inDrawer;

  static const List<(String, List<_NavItem>)> _sections = [
    (
      '',
      [_NavItem(Routes.dashboard, 'Dashboard', Icons.dashboard_outlined)],
    ),
    (
      'CRM',
      [_NavItem(Routes.contacts, 'Contacts', Icons.mail_outline_rounded)],
    ),
    (
      'CMS',
      [
        _NavItem(Routes.projects, 'Projects', Icons.work_outline_rounded),
        _NavItem(Routes.services, 'Services', Icons.miscellaneous_services_outlined),
        _NavItem(Routes.packages, 'Packages', Icons.sell_outlined),
        _NavItem(Routes.testimonials, 'Testimonials', Icons.format_quote_rounded),
      ],
    ),
    (
      'System',
      [_NavItem(Routes.settings, 'Settings', Icons.settings_outlined)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final shell = getIt<ShellController>();
    final auth = getIt<AuthController>();
    final theme = Theme.of(context);
    final railOnly = collapsed && !inDrawer;

    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _BrandHeader(collapsed: railOnly),
            Divider(color: theme.colorScheme.outlineVariant),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  for (final section in _sections) ...[
                    if (section.$1.isNotEmpty) ...[
                      if (!railOnly)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.xs,
                          ),
                          child: Text(
                            section.$1.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Divider(height: 1),
                        ),
                    ],
                    for (final item in section.$2)
                      _SidebarTile(item: item, railOnly: railOnly, shell: shell),
                  ],
                ],
              ),
            ),
            Divider(color: theme.colorScheme.outlineVariant),
            _ProfileTile(auth: auth, railOnly: railOnly),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.headerHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.smAll,
              ),
              child: const Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            if (!collapsed) ...[
              AppSpacing.w12,
              const Expanded(
                child: Text(
                  'SoftKormo',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.railOnly, required this.shell});

  final _NavItem item;
  final bool railOnly;
  final ShellController shell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
      child: Obx(() {
        final active = shell.isActive(item.route);
        final background = active ? theme.colorScheme.primaryContainer : Colors.transparent;
        final foreground = active
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;

        final content = InkWell(
          borderRadius: AppRadius.smAll,
          onTap: () => shell.openPage(item.route),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 19, color: foreground),
                if (!railOnly) ...[
                  AppSpacing.w12,
                  Expanded(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        if (railOnly) return Tooltip(message: item.label, child: content);
        return content;
      }),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.auth, required this.railOnly});

  final AuthController auth;
  final bool railOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Obx(() {
        final admin = auth.admin.value;
        final name = admin?.name ?? 'Admin';
        final email = admin?.email ?? '';

        final profile = InkWell(
          borderRadius: AppRadius.smAll,
          onTap: railOnly ? null : () => shellGoSettings(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (!railOnly) ...[
                  AppSpacing.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        final logout = AppIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'Sign out',
          onPressed: auth.signOut,
        );

        if (railOnly) {
          return Column(children: [profile, logout]);
        }
        return Row(
          children: [Expanded(child: profile), logout],
        );
      }),
    );
  }

  void shellGoSettings(BuildContext context) {
    getIt<ShellController>().openPage(Routes.settings);
  }
}

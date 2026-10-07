import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/shell/shell_controller.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/contacts/presentation/contacts_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/packages/domain/package_plan.dart';
import '../../features/packages/presentation/package_form_page.dart';
import '../../features/packages/presentation/packages_page.dart';
import '../../features/projects/domain/project.dart';
import '../../features/projects/presentation/project_form_page.dart';
import '../../features/projects/presentation/projects_page.dart';
import '../../features/services/domain/service_item.dart';
import '../../features/services/presentation/service_form_page.dart';
import '../../features/services/presentation/services_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/testimonials/domain/testimonial.dart';
import '../../features/testimonials/presentation/testimonial_form_page.dart';
import '../../features/testimonials/presentation/testimonials_page.dart';
import '../../app/shell/shell_route_observer.dart';
import 'admin_header.dart';
import 'admin_sidebar.dart';

/// Root layout: sidebar + header + content.
///
/// The shell is built once per session. Pages are swapped inside its own
/// [Navigator], so navigation never rebuilds the sidebar, the header or any
/// already loaded data.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late final ShellController _shell = getIt<ShellController>();
  late final AuthController _auth = getIt<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _shell.scaffoldKey,
      drawer: Responsive.isMobile(context)
          ? const Drawer(child: AdminSidebar(inDrawer: true))
          : null,
      body: Obx(() {
        // Wait for the restored admin profile before showing content.
        if (_auth.admin.value == null) return const _SessionLoading();
        return _buildLayout(context);
      }),
    );
  }

  Widget _buildLayout(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Row(
      children: [
        if (!isMobile)
          Obx(() {
            final tablet = Responsive.isTablet(context);
            final collapsed = _shell.sidebarCollapsed.value || tablet;
            final width = collapsed
                ? AppDimensions.sidebarCollapsedWidth
                : AppDimensions.sidebarWidth;
            return Container(
              width: width,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: AdminSidebar(collapsed: collapsed),
            );
          }),
        Expanded(
          child: Column(
            children: [
              const AdminHeader(),
              Expanded(child: _ShellNavigator(shell: _shell)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Content area of the shell - the only part that changes when navigating.
class _ShellNavigator extends StatelessWidget {
  const _ShellNavigator({required this.shell});

  final ShellController shell;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: shell.navigatorKey,
      initialRoute: Routes.dashboard,
      observers: [ShellRouteObserver(shell)],
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.contacts:
        return _page(settings.name, const ContactsPage());
      case Routes.projects:
        return _page(settings.name, const ProjectsPage());
      case Routes.projectNew:
        return _page(settings.name, const ProjectFormPage());
      case Routes.projectEdit:
        return _page(
          settings.name,
          ProjectFormPage(project: settings.arguments as Project),
        );
      case Routes.services:
        return _page(settings.name, const ServicesPage());
      case Routes.serviceNew:
        return _page(settings.name, const ServiceFormPage());
      case Routes.serviceEdit:
        return _page(
          settings.name,
          ServiceFormPage(service: settings.arguments as ServiceItem),
        );
      case Routes.packages:
        return _page(settings.name, const PackagesPage());
      case Routes.packageNew:
        return _page(settings.name, const PackageFormPage());
      case Routes.packageEdit:
        return _page(
          settings.name,
          PackageFormPage(package: settings.arguments as PackagePlan),
        );
      case Routes.testimonials:
        return _page(settings.name, const TestimonialsPage());
      case Routes.testimonialNew:
        return _page(settings.name, const TestimonialFormPage());
      case Routes.testimonialEdit:
        return _page(
          settings.name,
          TestimonialFormPage(testimonial: settings.arguments as Testimonial),
        );
      case Routes.settings:
        return _page(settings.name, const SettingsPage());
      case Routes.dashboard:
      default:
        return _page(Routes.dashboard, const DashboardPage());
    }
  }

  /// Instant transitions: an admin tool should feel immediate.
  Route<dynamic> _page(String? name, Widget child) => PageRouteBuilder(
        settings: RouteSettings(name: name),
        pageBuilder: (_, _, _) => child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, _, _, child) => child,
      );
}

class _SessionLoading extends StatelessWidget {
  const _SessionLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          AppSpacing.h16,
          Text('Restoring session...', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

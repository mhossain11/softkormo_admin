import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/shell_controller.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/admin_page_header.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/stat_card.dart';
import 'dashboard_charts.dart';
import 'dashboard_controller.dart';

/// Dashboard root: loads independent sections (stats, recent contacts,
/// charts) so a slow query never blocks the whole page.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController _controller = getIt<DashboardController>()..loadAll();

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminPageHeader(
            title: 'Dashboard',
            subtitle: 'Content and lead overview',
          ),
          _StatsSection(controller: _controller),
          AppSpacing.h24,
          ResponsiveBuilder(
            mobile: (_) => Column(
              children: [
                RecentContactsCard(controller: _controller),
                AppSpacing.h16,
                DashboardCharts(controller: _controller),
              ],
            ),
            desktop: (_) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: RecentContactsCard(controller: _controller)),
                AppSpacing.w16,
                Expanded(flex: 7, child: DashboardCharts(controller: _controller)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final shell = getIt<ShellController>();

    return Obx(() {
      final error = controller.statsError.value;
      final data = controller.stats.value;
      final isLoading = controller.statsLoading.value;

      if (error != null) {
        return SectionError(message: error, onRetry: controller.loadStats);
      }

      return Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.lg,
        children: [
          SizedBox(
            width: 232,
            child: StatCard(
              label: 'Total Contacts',
              value: (data?.totalContacts ?? 0).toString(),
              icon: Icons.mail_outline_rounded,
              color: AppColors.info,
              loading: isLoading,
              onTap: () => shell.openPage(Routes.contacts),
            ),
          ),
          SizedBox(
            width: 232,
            child: StatCard(
              label: 'New Contacts',
              value: (data?.newContacts ?? 0).toString(),
              icon: Icons.mark_email_unread_outlined,
              color: AppColors.accent,
              loading: isLoading,
              onTap: () => shell.openPage(Routes.contacts),
            ),
          ),
          SizedBox(
            width: 232,
            child: StatCard(
              label: 'Projects',
              value: (data?.projects ?? 0).toString(),
              icon: Icons.work_outline_rounded,
              color: AppColors.primary,
              loading: isLoading,
              onTap: () => shell.openPage(Routes.projects),
            ),
          ),
          SizedBox(
            width: 232,
            child: StatCard(
              label: 'Services',
              value: (data?.services ?? 0).toString(),
              icon: Icons.miscellaneous_services_outlined,
              color: const Color(0xFF7C3AED),
              loading: isLoading,
              onTap: () => shell.openPage(Routes.services),
            ),
          ),
          SizedBox(
            width: 232,
            child: StatCard(
              label: 'Packages',
              value: (data?.packages ?? 0).toString(),
              icon: Icons.sell_outlined,
              color: AppColors.warning,
              loading: isLoading,
              onTap: () => shell.openPage(Routes.packages),
            ),
          ),
          SizedBox(
            width: 232,
            child: StatCard(
              label: 'Testimonials',
              value: (data?.testimonials ?? 0).toString(),
              icon: Icons.format_quote_rounded,
              color: const Color(0xFFDB2777),
              loading: isLoading,
              onTap: () => shell.openPage(Routes.testimonials),
            ),
          ),
        ],
      );
    });
  }
}

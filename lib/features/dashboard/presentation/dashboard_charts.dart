import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/network_image_view.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/utils/formatters.dart';
import '../../contacts/domain/contact.dart';
import '../domain/dashboard_stats.dart';
import 'dashboard_controller.dart';

/// Error block reused by the dashboard sections.
class SectionError extends StatelessWidget {
  const SectionError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ErrorState(message: message, onRetry: onRetry),
    );
  }
}

/// Latest leads with a shortcut to the contacts inbox.
class RecentContactsCard extends StatelessWidget {
  const RecentContactsCard({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.recentLoading.value) {
        return const AppCard(title: 'Recent contacts', child: LoadingState());
      }
      final error = controller.recentError.value;
      if (error != null) {
        return AppCard(
          title: 'Recent contacts',
          child: ErrorState(message: error, onRetry: controller.loadRecentContacts),
        );
      }
      final contacts = controller.recentContacts;
      if (contacts.isEmpty) {
        return const AppCard(
          title: 'Recent contacts',
          child: EmptyState(
            icon: Icons.mail_outline_rounded,
            title: 'No contacts yet',
            message: 'Leads from your website contact form appear here.',
          ),
        );
      }

      return AppCard(
        title: 'Recent contacts',
        subtitle: 'Newest submissions first',
        child: Column(
          children: [
            for (var i = 0; i < contacts.length; i++) ...[
              if (i > 0) Divider(color: theme.colorScheme.outlineVariant, height: 1),
              _RecentContactRow(contact: contacts[i]),
            ],
          ],
        ),
      );
    });
  }
}

class _RecentContactRow extends StatelessWidget {
  const _RecentContactRow({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialAvatar(name: contact.name),
          AppSpacing.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        contact.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    StatusChip.of(contact.status, dense: true),
                  ],
                ),
                AppSpacing.h4,
                Text(
                  [
                    if (contact.email.isNotEmpty) contact.email,
                    if (contact.service.isNotEmpty) contact.service,
                  ].join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.w12,
          Text(
            Formatters.relativeTime(contact.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Monthly contact volume + contact status breakdown.
class DashboardCharts extends StatelessWidget {
  const DashboardCharts({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.chartsLoading.value) {
        return const AppCard(title: 'Activity', child: LoadingState());
      }
      final error = controller.chartsError.value;
      if (error != null) {
        return AppCard(
          title: 'Activity',
          child: ErrorState(message: error, onRetry: controller.loadCharts),
        );
      }

      return ResponsiveBuilder(
        mobile: (_) => Column(
          children: [
            _MonthlyContactsCard(data: controller.monthlyContacts),
            AppSpacing.h16,
            _StatusBreakdownCard(data: controller.statusCounts),
          ],
        ),
        desktop: (_) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _MonthlyContactsCard(data: controller.monthlyContacts)),
            AppSpacing.w16,
            Expanded(child: _StatusBreakdownCard(data: controller.statusCounts)),
          ],
        ),
      );
    });
  }
}

class _MonthlyContactsCard extends StatelessWidget {
  const _MonthlyContactsCard({required this.data});

  final List<LabelCount> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return const AppCard(title: 'Monthly contacts', child: EmptyState(title: 'No data yet'));
    }

    var max = 1;
    for (final item in data) {
      if (item.count > max) max = item.count;
    }

    return AppCard(
      title: 'Monthly contacts',
      subtitle: 'Contacts received in the last ${data.length} months',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: max * 1.25,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                  '${rod.toY.round()} contacts',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: theme.colorScheme.outlineVariant,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        data[index].label,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < data.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].count.toDouble(),
                      color: AppColors.primary,
                      width: 16,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
            ],
          ),
          duration: const Duration(milliseconds: 250),
        ),
      ),
    );
  }
}

class _StatusBreakdownCard extends StatelessWidget {
  const _StatusBreakdownCard({required this.data});

  final List<LabelCount> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = data.fold<int>(0, (sum, item) => sum + item.count);
    if (total == 0) {
      return const AppCard(title: 'Contact status', child: EmptyState(title: 'No data yet'));
    }

    return AppCard(
      title: 'Contact status',
      subtitle: 'Pipeline breakdown',
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 42,
                sectionsSpace: 2,
                sections: [
                  for (final item in data)
                    if (item.count > 0)
                      PieChartSectionData(
                        value: item.count.toDouble(),
                        color: StatusStyles.meta(item.label).color,
                        radius: 46,
                        title: total == 0
                            ? ''
                            : '${(item.count / total * 100).round()}%',
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                ],
              ),
            ),
          ),
          AppSpacing.h16,
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in data)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: StatusStyles.meta(item.label).color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppSpacing.w8,
                    Text(
                      '${StatusStyles.meta(item.label).label} (${item.count})',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

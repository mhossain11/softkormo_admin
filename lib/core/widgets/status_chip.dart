import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Label + colors for a status value stored in Firestore.
class StatusMeta {
  const StatusMeta(this.label, this.color, this.background);

  final String label;
  final Color color;
  final Color background;
}

/// Central place for every status style used in the panel.
class StatusStyles {
  const StatusStyles._();

  static const Map<String, StatusMeta> _styles = {
    'new': StatusMeta('New', AppColors.info, AppColors.infoBg),
    'contacted': StatusMeta('Contacted', AppColors.warning, AppColors.warningBg),
    'qualified': StatusMeta('Qualified', Color(0xFF7C3AED), Color(0xFFF1EBFE)),
    'converted': StatusMeta('Converted', AppColors.success, AppColors.successBg),
    'closed': StatusMeta('Closed', AppColors.neutral, AppColors.neutralBg),
    'published': StatusMeta('Published', AppColors.success, AppColors.successBg),
    'unpublished': StatusMeta('Unpublished', AppColors.neutral, AppColors.neutralBg),
    'draft': StatusMeta('Draft', AppColors.neutral, AppColors.neutralBg),
    'active': StatusMeta('Active', AppColors.success, AppColors.successBg),
    'inactive': StatusMeta('Inactive', AppColors.danger, AppColors.dangerBg),
    'featured': StatusMeta('Featured', Color(0xFFB45309), Color(0xFFFDF3E3)),
    'recommended': StatusMeta('Recommended', AppColors.primary, AppColors.primaryLight),
  };

  static StatusMeta meta(String key) {
    final normalized = key.trim().toLowerCase();
    final found = _styles[normalized];
    if (found != null) return found;
    final label = normalized.isEmpty
        ? '—'
        : normalized[0].toUpperCase() + normalized.substring(1);
    return StatusMeta(label, AppColors.neutral, AppColors.neutralBg);
  }

  static StatusMeta ofFlag(bool value, {required String whenTrue, required String whenFalse}) =>
      meta(value ? whenTrue : whenFalse);
}

/// Small pill used for statuses and boolean flags.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
    this.dense = false,
  });

  factory StatusChip.of(String status, {IconData? icon, bool dense = false}) {
    final meta = StatusStyles.meta(status);
    return StatusChip(
      label: meta.label,
      color: meta.color,
      background: meta.background,
      icon: icon,
      dense: dense,
    );
  }

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 2 : 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

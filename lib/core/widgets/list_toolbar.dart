import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_search_field.dart';

/// Search + optional filter control + "clear filters" action shared by every
/// CMS list screen.
///
/// Wrap the toolbar in an [Obx] when [filter] or [hasActiveFilters] depend on
/// reactive controller state.
class ListToolbar extends StatelessWidget {
  const ListToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    this.searchHint = 'Search...',
    this.searchWidth = 300,
    this.filter,
    this.hasActiveFilters = false,
    this.onClearFilters,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String searchHint;
  final double searchWidth;

  /// Usually an [AppDropdown] for the module's single filter slot.
  final Widget? filter;

  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppSearchField(
          controller: searchController,
          hint: searchHint,
          width: searchWidth,
          onChanged: onSearchChanged,
        ),
        ?filter,
        if (hasActiveFilters && onClearFilters != null)
          AppButton(
            label: 'Clear',
            variant: AppButtonVariant.text,
            icon: Icons.filter_alt_off_outlined,
            onPressed: onClearFilters,
          ),
      ],
    );
  }
}

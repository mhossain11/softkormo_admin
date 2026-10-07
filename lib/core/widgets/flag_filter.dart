import 'package:flutter/material.dart';

import 'app_dropdown.dart';

/// Boolean filter dropdown used by lists with a `published` / `active` slot
/// (services, packages, testimonials).
class FlagFilter extends StatelessWidget {
  const FlagFilter({
    super.key,
    required this.value,
    required this.onChanged,
    required this.allLabel,
    required this.trueLabel,
    required this.falseLabel,
    this.width = 180,
  });

  final bool? value;
  final ValueChanged<bool?> onChanged;
  final String allLabel;
  final String trueLabel;
  final String falseLabel;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AppDropdown<bool?>(
      value: value,
      hint: allLabel,
      width: width,
      items: [
        DropdownItem<bool?>(value: null, label: allLabel),
        DropdownItem<bool?>(value: true, label: trueLabel),
        DropdownItem<bool?>(value: false, label: falseLabel),
      ],
      onChanged: onChanged,
    );
  }
}

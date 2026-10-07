import 'package:flutter/material.dart';

/// One entry of an [AppDropdown].
class DropdownItem<T> {
  const DropdownItem({required this.value, required this.label, this.leading});

  final T value;
  final String label;
  final Widget? leading;
}

/// Typed dropdown used for every filter and select field.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.validator,
    this.expanded = true,
    this.width,
    this.enabled = true,
    this.dense = false,
  });

  final List<DropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? label;
  final String? hint;
  final FormFieldValidator<T>? validator;
  final bool expanded;
  final double? width;
  final bool enabled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final field = DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: expanded,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.leading != null) ...[item.leading!, const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: const Icon(Icons.expand_more_rounded, size: 18),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 8 : 12),
      ),
    );
    if (width == null) return field;
    return SizedBox(width: width, child: field);
  }
}

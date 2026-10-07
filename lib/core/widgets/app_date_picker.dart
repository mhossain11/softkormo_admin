import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import 'app_text_field.dart';

/// Read-only text field that opens the Material date picker.
class AppDatePicker extends StatefulWidget {
  const AppDatePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.firstDate,
    this.lastDate,
    this.hint,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool required;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? hint;

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  late final TextEditingController _controller =
      TextEditingController(text: _format(widget.value));

  static String _format(DateTime? value) =>
      value == null ? '' : Formatters.date.format(value);

  @override
  void didUpdateWidget(AppDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: widget.value ?? now,
      firstDate: widget.firstDate ?? DateTime(now.year - 30),
      lastDate: widget.lastDate ?? DateTime(now.year + 10),
    );
    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hint: widget.hint,
      required: widget.required,
      readOnly: true,
      controller: _controller,
      onTap: _pick,
      suffixIcon: IconButton(
        tooltip: 'Pick a date',
        iconSize: 18,
        onPressed: _pick,
        icon: const Icon(Icons.calendar_today_outlined),
      ),
      validator: widget.required
          ? (value) => (value == null || value.trim().isEmpty) ? '${widget.label} is required.' : null
          : null,
    );
  }
}

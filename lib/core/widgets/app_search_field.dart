import 'package:flutter/material.dart';

import '../utils/debouncer.dart';

/// Search input with built-in debounce: [onChanged] fires only after the user
/// stopped typing, so Firestore is never queried per keystroke.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.onChanged,
    this.controller,
    this.hint = 'Search...',
    this.debounce = const Duration(milliseconds: 400),
    this.width = 300,
    this.autofocus = false,
  });

  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final String hint;
  final Duration debounce;
  final double width;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final Debouncer _debouncer =
      Debouncer(delay: widget.debounce, onInput: widget.onChanged);
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleChange);
  }

  void _handleChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText && mounted) setState(() => _hasText = hasText);
    _debouncer(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    if (widget.controller == null) _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.width),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        style: const TextStyle(fontSize: 14),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          suffixIcon: _hasText
              ? IconButton(
                  tooltip: 'Clear search',
                  iconSize: 16,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
        ),
      ),
    );
  }
}

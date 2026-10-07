import 'dart:async';

/// Triggers [onInput] after [delay] has elapsed since the last change.
/// Used for search fields so Firestore is not queried per keystroke.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 400), required this.onInput});

  final Duration delay;
  final void Function(String value) onInput;
  Timer? _timer;

  void call(String value) {
    _timer?.cancel();
    _timer = Timer(delay, () => onInput(value));
  }

  void dispose() => _timer?.cancel();
}

import 'package:intl/intl.dart';

/// Display formatting helpers.
class Formatters {
  const Formatters._();

  static final NumberFormat _number = NumberFormat.decimalPattern();
  static final DateFormat date = DateFormat.yMMMd();
  static final DateFormat dateTime = DateFormat.yMMMd().add_jm();
  static final DateFormat monthLabel = DateFormat.MMM();

  static String number(num value) => _number.format(value);

  static String money(num value, String currency) {
    final symbol = switch (currency.toUpperCase()) {
      'USD' => r'$',
      'EUR' => '€',
      'GBP' => '£',
      'BDT' => '৳',
      'INR' => '₹',
      _ => '',
    };
    if (symbol.isEmpty) return '${_number.format(value)} ${currency.toUpperCase()}';
    return '$symbol${_number.format(value)}';
  }

  static String dateOrDash(DateTime? value) => value == null ? '—' : date.format(value.toLocal());

  static String dateTimeOrDash(DateTime? value) => value == null ? '—' : dateTime.format(value.toLocal());

  /// Compact text for "3 days ago" style labels.
  static String relativeTime(DateTime? value) {
    if (value == null) return '—';
    final diff = DateTime.now().toUtc().difference(value.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return date.format(value.toLocal());
  }

  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

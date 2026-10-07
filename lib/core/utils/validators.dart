/// Form validation helpers shared by every screen.
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final RegExp _url = RegExp(r'^(https?|ftp)://[^\s/$.?#].[^\s]*$', caseSensitive: false);

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required.';
    if (!_email.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required.';
    if (v.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? url(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // Optional field.
    if (!_url.hasMatch(v)) return 'Enter a valid URL (https://...).';
    return null;
  }

  static String? integer(String? value, {int? min, int? max}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter a number.';
    final n = int.tryParse(v);
    if (n == null) return 'Enter a whole number.';
    if (min != null && n < min) return 'Must be $min or more.';
    if (max != null && n > max) return 'Must be $max or less.';
    return null;
  }

  static String? number(String? value, {double? min, double? max}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter an amount.';
    final n = double.tryParse(v.replaceAll(',', ''));
    if (n == null) return 'Enter a valid amount.';
    if (min != null && n < min) return 'Must be ${_bound(min)} or more.';
    if (max != null && n > max) return 'Must be ${_bound(max)} or less.';
    return null;
  }

  /// Formats a numeric bound without a trailing ".0" (1 instead of 1.0).
  static String _bound(num value) => value == value.toInt() ? '${value.toInt()}' : '$value';

  /// Validates a newline / list based input with at least one entry.
  static String? list(String? value, [String field = 'Add at least one item']) {
    final items = splitList(value);
    if (items.isEmpty) return field;
    return null;
  }

  /// Splits comma or newline separated input into trimmed, non-empty items.
  static List<String> splitList(String? value) => (value ?? '')
      .split(RegExp(r'[,\n]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  /// Rating must be between 1 and 5.
  static String? rating(int value) {
    if (value < 1 || value > 5) return 'Rating must be between 1 and 5.';
    return null;
  }
}

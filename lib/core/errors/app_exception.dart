/// Application level exception carrying a message that is safe to show
/// to the user. Raw Firebase errors must never reach the UI.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// User friendly message.
  final String message;

  /// Original error, kept for logging only.
  final Object? cause;

  @override
  String toString() => message;
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'app_exception.dart';

/// Converts any thrown object into an [AppException] with a message that is
/// safe to display. Users should never see raw Firebase error codes.
class ErrorMessages {
  const ErrorMessages._();

  static String describe(Object error) {
    if (error is AppException) return error.message;
    if (error is FirebaseAuthException) return _auth(error.code);
    if (error is FirebaseException) return _firestore(error);
    if (error is PlatformException) {
      return 'The operation could not be completed. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  static AppException asException(Object error) =>
      error is AppException ? error : AppException(describe(error), cause: error);

  static String _auth(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
      case 'email-already-in-use':
        return 'This email address is already registered.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'internal-error':
        return 'Authentication service is unavailable. Please try again.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }

  static String _firestore(FirebaseException error) {
    final code = error.code;
    if (code.contains('permission-denied')) {
      return 'You do not have permission to perform this action.';
    }
    if (code.contains('unavailable') || code.contains('network')) {
      return 'Network error. Check your connection and try again.';
    }
    if (code.contains('not-found')) {
      return 'The requested item no longer exists.';
    }
    if (code.contains('already-exists')) {
      return 'An item with this identifier already exists.';
    }
    if (code.contains('failed-precondition')) {
      return 'The request could not be completed. Required setup is missing.';
    }
    if (code.contains('resource-exhausted')) {
      return 'Service is temporarily overloaded. Please try again shortly.';
    }
    if (error.plugin.contains('storage')) {
      return 'File operation failed. Please try again.';
    }
    return 'A service error occurred. Please try again.';
  }
}

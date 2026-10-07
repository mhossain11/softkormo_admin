import 'package:firebase_auth/firebase_auth.dart';

import '../errors/app_exception.dart';
import '../errors/error_messages.dart';
import 'firebase_service.dart';

/// Thin wrapper around Firebase Authentication.
class AuthService {
  AuthService(this._firebase);

  final FirebaseService _firebase;

  FirebaseAuth get _auth => _firebase.auth;

  /// Emits on sign-in, sign-out and on restored sessions.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently persisted Firebase user, if any.
  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserCredential> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw ErrorMessages.asException(e);
    }
  }

  /// Throws [AppException] when the Firebase layer fails.
  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ErrorMessages.asException(e);
    }
  }
}

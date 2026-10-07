import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../domain/admin_user.dart';

/// Authentication + administrator profile access.
///
/// Flow: Firebase Auth -> uid -> `admins/{uid}` -> active check -> profile.
class AuthRepository {
  AuthRepository(this._auth, this._firestore);

  final AuthService _auth;
  final FirestoreService _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges;

  User? get currentFirebaseUser => _auth.currentFirebaseUser;

  /// Only performs the Firebase Auth sign-in and returns the authenticated
  /// user. Profile validation happens through [restoreSession].
  Future<User> signInWithCredentials({required String email, required String password}) async {
    final UserCredential credential;
    try {
      credential = await _auth.signIn(email: email, password: password);
    } catch (e) {
      throw ErrorMessages.asException(e);
    }
    final user = credential.user;
    if (user == null) {
      throw const AppException('Sign-in failed. Please try again.');
    }
    return user;
  }

  /// Reads `admins/{uid}` and validates the account.
  ///
  /// Returns `null` when no user is signed in. Signs the user out when the
  /// profile is missing or the account is deactivated.
  Future<AdminUser?> restoreSession() async {
    final user = currentFirebaseUser;
    if (user == null) return null;
    return _loadProfile(user.uid);
  }

  Future<AdminUser> _loadProfile(String uid) async {
    try {
      final data = await _firestore.getDocument('${AdminUser.collection}/$uid');
      if (data == null) {
        await _safeSignOut();
        throw const AppException('This account is not registered as an administrator.');
      }
      final admin = AdminUser.fromMap(data, uid: uid);
      if (!admin.active) {
        await _safeSignOut();
        throw const AppException('This account has been deactivated. Contact the owner.');
      }
      return admin;
    } on AppException {
      rethrow;
    } catch (e) {
      await _safeSignOut();
      throw ErrorMessages.asException(e);
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> _safeSignOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Sign-out failures must not mask the original problem.
    }
  }
}

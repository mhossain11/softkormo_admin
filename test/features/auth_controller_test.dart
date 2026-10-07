import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:softkormoadmin/core/errors/app_exception.dart';
import 'package:softkormoadmin/features/auth/data/auth_repository.dart';
import 'package:softkormoadmin/features/auth/domain/admin_user.dart';
import 'package:softkormoadmin/features/auth/presentation/auth_controller.dart';

/// Minimal [User] double - the controller only reads `uid`.
class FakeUser implements User {
  FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// In-memory [AuthRepository]: emits auth events and serves a profile
/// without touching Firebase.
class FakeAuthRepository implements AuthRepository {
  final StreamController<User?> _changes = StreamController<User?>.broadcast();

  User? current;
  AdminUser? profile;
  Object? signInError;
  Object? restoreError;
  int restoreCalls = 0;
  int signOutCalls = 0;
  bool signedOut = false;

  @override
  Stream<User?> get authStateChanges => _changes.stream;

  @override
  User? get currentFirebaseUser => current;

  @override
  Future<User> signInWithCredentials({required String email, required String password}) async {
    if (signInError != null) throw signInError!;
    current = FakeUser('uid-1');
    return current!;
  }

  @override
  Future<AdminUser?> restoreSession() async {
    restoreCalls++;
    if (restoreError != null) throw restoreError!;
    if (signedOut) return null;
    return profile;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    signedOut = true;
    current = null;
    _changes.add(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void emit(User? user) => _changes.add(user);

  void dispose() => _changes.close();
}

AdminUser _admin({bool active = true, String role = AdminUser.roleAdmin}) => AdminUser(
      uid: 'uid-1',
      name: 'Faysal Rahman',
      email: 'admin@softkormo.com',
      role: role,
      active: active,
    );

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late FakeAuthRepository repository;
  late AuthController controller;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.testMode = true;
    repository = FakeAuthRepository();
    controller = AuthController(repository);
    controller.start();
  });

  tearDown(() {
    controller.onClose();
    repository.dispose();
    Get.testMode = false;
  });

  group('AuthController.start', () {
    test('loads the admin profile when Firebase reports a session', () async {
      repository
        ..profile = _admin()
        ..current = FakeUser('uid-1');
      expect(controller.isAuthenticated, isFalse);
      expect(controller.hasFirebaseSession, isTrue);

      repository.emit(FakeUser('uid-1'));
      await _settle();

      expect(controller.isAuthenticated, isTrue);
      expect(controller.admin.value!.uid, 'uid-1');
      expect(controller.admin.value!.name, 'Faysal Rahman');
      expect(controller.restoring.value, isFalse);
      expect(repository.restoreCalls, 1);
    });

    test('clears the profile when the session ends', () async {
      repository
        ..profile = _admin()
        ..current = FakeUser('uid-1');
      repository.emit(FakeUser('uid-1'));
      await _settle();
      expect(controller.isAuthenticated, isTrue);

      repository.emit(null);
      await _settle();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.admin.value, isNull);
    });

    test('a missing profile never authenticates', () async {
      repository.current = FakeUser('uid-1');
      repository.emit(FakeUser('uid-1'));
      await _settle();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.errorMessage.value, isNull);
    });
  });

  group('AuthController before the first frame', () {
    test('auth events never navigate without a mounted navigator', () async {
      // Production configuration: no test shortcuts and no GetMaterialApp, so
      // `Get.key.currentContext` is null exactly as it is before the first
      // frame. Navigating here used to throw GetX's "contextless navigation"
      // error straight out of the auth stream listener.
      Get.testMode = false;
      repository
        ..profile = _admin()
        ..current = FakeUser('uid-1');
      Object? zoneError;
      late AuthController early;

      runZonedGuarded(
        () {
          early = AuthController(repository)..start();
          repository.emit(null); // Firebase reports "signed out"
          repository.emit(FakeUser('uid-1')); // and then a restored session
        },
        (Object error, StackTrace _) => zoneError = error,
      );

      await _settle();

      expect(zoneError, isNull);
      expect(early.isAuthenticated, isTrue);
      expect(early.admin.value!.uid, 'uid-1');

      early.onClose();
      Get.testMode = true;
    });
  });

  group('AuthController.signIn', () {
    test('signs in and validates the admin profile', () async {
      repository.profile = _admin(role: AdminUser.roleSuperAdmin);

      final ok = await controller.signIn(
        email: 'admin@softkormo.com',
        password: 'secret123',
      );

      expect(ok, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.admin.value!.isSuperAdmin, isTrue);
      expect(controller.signingIn.value, isFalse);
      expect(controller.errorMessage.value, isNull);
      expect(repository.restoreCalls, 1);
    });

    test('rejects unknown accounts without leaving the user signed in', () async {
      repository.profile = null;

      final ok = await controller.signIn(
        email: 'stranger@softkormo.com',
        password: 'secret123',
      );

      expect(ok, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.signingIn.value, isFalse);
    });

    test('reports repository failures with a friendly message', () async {
      repository.signInError = const AppException('Incorrect email or password.');

      final ok = await controller.signIn(
        email: 'admin@softkormo.com',
        password: 'wrong',
      );

      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Incorrect email or password.');
      expect(controller.signingIn.value, isFalse);
      expect(controller.isAuthenticated, isFalse);
    });

    test('reports a deactivated profile', () async {
      repository.profile = _admin(active: false);
      repository.restoreError = const AppException(
        'This account has been deactivated. Contact the owner.',
      );

      final ok = await controller.signIn(
        email: 'admin@softkormo.com',
        password: 'secret123',
      );

      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'This account has been deactivated. Contact the owner.');
      expect(controller.isAuthenticated, isFalse);
    });

    test('clearError removes the last message', () async {
      repository.signInError = const AppException('Sign-in failed.');
      await controller.signIn(email: 'a@b.com', password: 'secret123');
      expect(controller.errorMessage.value, isNotNull);

      controller.clearError();

      expect(controller.errorMessage.value, isNull);
    });
  });

  group('AuthController.signOut', () {
    test('delegates to the repository and resets the profile', () async {
      repository.profile = _admin();
      repository.current = FakeUser('uid-1');
      repository.emit(FakeUser('uid-1'));
      await _settle();
      expect(controller.isAuthenticated, isTrue);

      await controller.signOut();
      await _settle();

      expect(repository.signOutCalls, 1);
      expect(controller.isAuthenticated, isFalse);
    });
  });
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../data/auth_repository.dart';
import '../domain/admin_user.dart';

/// Owns the authentication state of the panel.
///
/// A profile (`admins/{uid}`) is read exactly once per auth event and is
/// shared between the state listener and the login form.
class AuthController extends GetxController {
  AuthController(this._repository);

  final AuthRepository _repository;

  final Rxn<AdminUser> admin = Rxn<AdminUser>();
  final RxBool signingIn = false.obs;
  final RxBool restoring = false.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<User?>? _subscription;
  Future<void>? _restoreJob;
  String? _restoreJobUid;

  bool get isAuthenticated => admin.value != null;

  /// True when a persisted Firebase session exists (profile not loaded yet).
  bool get hasFirebaseSession => _repository.currentFirebaseUser != null;

  bool get isBusy => signingIn.value || restoring.value;

  @override
  void onInit() {
    super.onInit();
    start();
  }

  /// Starts the Firebase auth state listener.
  ///
  /// Controllers created through GetIt never receive GetX lifecycle
  /// callbacks, so `main()` calls this once at startup.
  void start() {
    if (_subscription != null) return;
    _subscription = _repository.authStateChanges.listen(
      _onAuthChanged,
      onError: (Object _) {},
    );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  void _onAuthChanged(User? user) {
    if (user == null) {
      admin.value = null;
      _restoreJob = null;
      _restoreJobUid = null;
      _redirect(_toLogin);
      return;
    }
    unawaited(_ensureProfile(user));
  }

  /// Runs [navigation] through the root navigator.
  ///
  /// The auth stream can emit before the first frame, i.e. before
  /// `GetMaterialApp` has attached its navigator. Navigating at that moment
  /// throws GetX's "contextless navigation" error, so the call is deferred to
  /// the end of the first frame - and the route check runs then as well,
  /// because `Get.currentRoute` is not populated before that.
  void _redirect(void Function() navigation) {
    void attempt([bool retry = true]) {
      // GetX itself refuses to navigate while `Get.key` has no context
      // ("contextless navigation"), so mirror its precondition here.
      if (Get.testMode || Get.key.currentContext != null) {
        navigation();
      } else if (retry) {
        WidgetsBinding.instance
          ..scheduleFrame()
          ..addPostFrameCallback((_) => attempt(false));
      }
    }

    attempt();
  }

  void _toLogin() {
    if (Get.currentRoute != Routes.login) {
      Get.offAllNamed(Routes.login);
    }
  }

  void _toAdmin() {
    if (Get.currentRoute == Routes.login) {
      Get.offAllNamed(Routes.admin);
    }
  }

  /// Loads `admins/{uid}` once, even when the listener and the login form
  /// both await it.
  Future<void> _ensureProfile(User user) {
    if (admin.value?.uid == user.uid) return Future<void>.value();
    final running = _restoreJob;
    if (running != null && _restoreJobUid == user.uid) return running;

    restoring.value = true;
    final job = _loadProfile(user).whenComplete(() {
      _restoreJob = null;
      _restoreJobUid = null;
      restoring.value = false;
    });
    _restoreJob = job;
    _restoreJobUid = user.uid;
    return job;
  }

  Future<void> _loadProfile(User user) async {
    try {
      final profile = await _repository.restoreSession();
      if (profile == null) return; // Repository already signed the user out.
      admin.value = profile;
      _redirect(_toAdmin);
    } catch (e) {
      admin.value = null;
      final message = ErrorMessages.describe(e);
      errorMessage.value = message;
      _redirect(_toLogin);
      WidgetsBinding.instance.addPostFrameCallback((_) => AppSnackbar.error(message));
    }
  }

  /// Signs in and waits for the admin profile to be validated.
  Future<bool> signIn({required String email, required String password}) async {
    if (signingIn.value) return false;
    signingIn.value = true;
    errorMessage.value = null;
    try {
      final user = await _repository.signInWithCredentials(email: email, password: password);
      await _ensureProfile(user);
      return admin.value != null;
    } catch (e) {
      final message = ErrorMessages.describe(e);
      errorMessage.value = message;
      AppSnackbar.error(message);
      return false;
    } finally {
      signingIn.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (e) {
      AppSnackbar.error(ErrorMessages.describe(e));
    }
  }

  void clearError() => errorMessage.value = null;
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/injection.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();

  // Register the auth listener before the first frame so a restored session
  // is validated (admins/{uid} active + role) without flashing the login page.
  getIt<AuthController>().start();

  runApp(const SoftKormoAdmin());
}

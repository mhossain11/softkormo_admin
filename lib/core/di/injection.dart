import 'package:get_it/get_it.dart';

import '../../app/theme_controller.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/contacts/data/contact_repository.dart';
import '../../features/contacts/presentation/contact_controller.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../features/dashboard/presentation/dashboard_controller.dart';
import '../../features/packages/data/package_repository.dart';
import '../../features/packages/presentation/package_controller.dart';
import '../../features/projects/data/project_repository.dart';
import '../../features/projects/presentation/project_controller.dart';
import '../../features/services/data/service_repository.dart';
import '../../features/services/presentation/service_controller.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/presentation/settings_controller.dart';
import '../../features/testimonials/data/testimonial_repository.dart';
import '../../features/testimonials/presentation/testimonial_controller.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../../app/shell/shell_controller.dart';
import '../data/media_storage.dart';

/// GetIt locator for the whole application.
///
/// Registration happens at startup but *initialization* is lazy:
/// * core Firebase services are singletons (created immediately),
/// * repositories are lazy singletons,
/// * feature controllers are lazy singletons, so the first `getIt.get<T>()`
///   happens when the related page is opened - never during startup.
final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<FirebaseService>()) return;

  // Core services (startup).
  getIt.registerSingleton<FirebaseService>(FirebaseService());
  getIt.registerSingleton<AuthService>(AuthService(getIt<FirebaseService>()));
  getIt.registerSingleton<FirestoreService>(FirestoreService(getIt<FirebaseService>()));
  getIt.registerSingleton<StorageService>(StorageService(getIt<FirebaseService>()));
  getIt.registerLazySingleton<MediaStorage>(() => MediaStorage(getIt<StorageService>()));

  // Repositories (lazy).
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<AuthService>(), getIt<FirestoreService>()),
  );
  getIt.registerLazySingleton<ContactRepository>(
    () => ContactRepository(getIt<FirestoreService>()),
  );
  getIt.registerLazySingleton<ProjectRepository>(
    () => ProjectRepository(getIt<FirestoreService>(), getIt<MediaStorage>()),
  );
  getIt.registerLazySingleton<ServiceRepository>(
    () => ServiceRepository(getIt<FirestoreService>()),
  );
  getIt.registerLazySingleton<PackageRepository>(
    () => PackageRepository(getIt<FirestoreService>()),
  );
  getIt.registerLazySingleton<TestimonialRepository>(
    () => TestimonialRepository(getIt<FirestoreService>(), getIt<MediaStorage>()),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(getIt<FirestoreService>(), getIt<MediaStorage>()),
  );
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(getIt<FirestoreService>()),
  );

  // Controllers (lazy - created when their page is first opened).
  getIt.registerLazySingleton<AuthController>(() => AuthController(getIt<AuthRepository>()));
  getIt.registerLazySingleton<ThemeController>(ThemeController.new);
  getIt.registerLazySingleton<ShellController>(ShellController.new);
  getIt.registerLazySingleton<DashboardController>(
    () => DashboardController(getIt<DashboardRepository>()),
  );
  getIt.registerLazySingleton<ContactController>(
    () => ContactController(getIt<ContactRepository>()),
  );
  getIt.registerLazySingleton<ProjectController>(
    () => ProjectController(getIt<ProjectRepository>()),
  );
  getIt.registerLazySingleton<ServiceController>(
    () => ServiceController(getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<PackageController>(
    () => PackageController(getIt<PackageRepository>()),
  );
  getIt.registerLazySingleton<TestimonialController>(
    () => TestimonialController(getIt<TestimonialRepository>()),
  );
  getIt.registerLazySingleton<SettingsController>(
    () => SettingsController(getIt<SettingsRepository>()),
  );
}

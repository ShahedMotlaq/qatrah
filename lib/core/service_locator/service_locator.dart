// lib/core/service_locator/service_locator.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/auth/app_lock_lifecycle_observer.dart';
import 'package:qatrah/core/auth/app_lock_state.dart';
import 'package:qatrah/core/auth/auth_session_service.dart';
import 'package:qatrah/core/auth/biometric_service.dart';
import 'package:qatrah/core/auth/fresh_install_marker.dart';
import 'package:qatrah/core/auth/pin_security_service.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/auth/session_notifier.dart';
import 'package:qatrah/core/events/profile_event_bus.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/locale/locale_cubit.dart';
import 'package:qatrah/core/network/api_client.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/network/network_alert_service.dart';
import 'package:qatrah/core/network/network_status_cubit.dart';
import 'package:qatrah/core/notification/notification_service.dart';
import 'package:qatrah/core/routing/app_router.dart';
import 'package:qatrah/core/services/connectivity_service.dart';
import 'package:qatrah/core/services/maintenance_state_service.dart';
import 'package:qatrah/core/services/settings_storage_service.dart';
import 'package:qatrah/core/services/toast_service.dart';
import 'package:qatrah/core/services/version_check_service.dart';
import 'package:qatrah/core/storage_service.dart';
import 'package:qatrah/features/auth/di/auth_injection.dart';
import 'package:qatrah/features/complaints/di/complaints_injection.dart';
import 'package:qatrah/features/employee/di/employee_injection.dart';
import 'package:qatrah/features/home/di/home_injection.dart';
import 'package:qatrah/features/notifications/di/notifications_injection.dart';
import 'package:qatrah/features/profile/di/profile_injection.dart';
import 'package:qatrah/features/water_feedback/di/water_feedback_injection.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  _registerCore();

  registerAuthDependencies(getIt);
  registerProfileDependencies(getIt);
  registerHomeDependencies(getIt);
  registerComplaintsDependencies(getIt);
  registerNotificationsDependencies(getIt);
  registerEmployeeDependencies(getIt);
  registerWaterFeedbackDependencies(getIt);

  // Routing — depends on core (SessionNotifier, AppLockState) being registered.
  getIt.registerLazySingleton<GoRouter>(() => AppRouter.router);
}

/// Core & infrastructure singletons shared by all features.
/// Must run before feature registrations resolve.
void _registerCore() {
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage(getIt()));
  getIt.registerLazySingleton<StorageService>(
    () => StorageService(getIt<SecureStorage>()),
  );
  getIt.registerLazySingleton<LocaleCubit>(() => LocaleCubit(getIt()));
  getIt.registerLazySingleton<SecureAuthStorage>(
    () => SecureAuthStorage(getIt()),
  );
  getIt.registerLazySingleton<AppLockState>(AppLockState.new);
  // Single source of truth for session-end signals. Registered before
  // ApiClient/GoRouter because both depend on it (interceptor emits, router
  // listens via refreshListenable).
  getIt.registerLazySingleton<SessionNotifier>(SessionNotifier.new);
  getIt.registerLazySingleton<NetworkAlertService>(
    () => NetworkAlertService.instance,
  );
  getIt.registerLazySingleton<ToastService>(() => ToastService.instance);
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      secureStorage: getIt(),
      lockState: getIt<AppLockState>(),
      authStorage: getIt<SecureAuthStorage>(),
      networkAlertService: getIt<NetworkAlertService>(),
      sessionNotifier: getIt<SessionNotifier>(),
    ),
  );
  getIt.registerLazySingleton<ApiService>(() {
    final apiService = ApiService(getIt());
    // Wire ApiService into the AuthInterceptor to enable auth header updates after token refresh
    getIt<ApiClient>().setApiServiceForInterceptor(apiService);
    return apiService;
  });
  getIt.registerLazySingleton<AuthSessionService>(
    () => AuthSessionService(
      secureStorage: getIt(),
      apiClient: getIt(),
      apiService: getIt(),
      sessionNotifier: getIt<SessionNotifier>(),
    ),
  );
  getIt.registerLazySingleton<PinSecurityService>(
    () => PinSecurityService(getIt()),
  );
  getIt.registerLazySingleton<BiometricService>(BiometricService.new);
  getIt.registerLazySingleton<FreshInstallMarker>(
    () => FreshInstallMarker(getIt(), getIt()),
  );
  getIt.registerLazySingleton<AppLockLifecycleObserver>(
    () => AppLockLifecycleObserver(
      lockState: getIt(),
      authStorage: getIt(),
      router: getIt(),
    ),
  );
  getIt.registerLazySingleton<ProfileEventBus>(
    () => ProfileEventBus.instance,
  );
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService.instance,
  );
  getIt.registerLazySingleton<SettingsStorageService>(
    () => SettingsStorageService.instance,
  );
  getIt.registerLazySingleton<ConnectivityService>(ConnectivityService.new);
  getIt.registerLazySingleton<MaintenanceStateService>(
    () => MaintenanceStateService(apiService: getIt()),
  );
  getIt.registerLazySingleton<VersionCheckService>(
    () => VersionCheckService(apiService: getIt()),
  );
  getIt.registerLazySingleton<NetworkStatusCubit>(
    () => NetworkStatusCubit(getIt<ConnectivityService>()),
  );
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/auth/app_lock_state.dart';
import 'package:qatrah/core/auth/auth_session_service.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/notification/notification_service.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/maintenance_state_service.dart';
import 'package:qatrah/core/services/version_check_service.dart';
import 'package:qatrah/core/utils/app_logger.dart';
import 'package:qatrah/features/splash/presentation/bloc/splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  /// Keep the user signed in indefinitely while they keep opening the app.
  /// Only a full 2 months (60 days) of the app never being opened forces a
  /// re-login on next launch.
  static const _sessionInactivityLimit = Duration(days: 60);

  Future<void> appStart() async {
    emit(SplashLoading());

    await Future<void>.delayed(const Duration(seconds: 2));

    // Ask for notifications here — on the splash, before the user reaches
    // login. The delay above guarantees the first frame is up, which Android
    // 13+ needs for the runtime prompt to actually appear. Awaited, so routing
    // waits for the user's answer; the result never gates entering the app.
    try {
      await getIt<NotificationService>().ensureNotificationPermission();
    } catch (e) {
      AppLogger.error('Notification permission request failed: $e');
    }

    final secureStorage = getIt<SecureStorage>();
    final authStorage = getIt<SecureAuthStorage>();
    final lockState = getIt<AppLockState>();
    final sessionService = getIt<AuthSessionService>();
    final maintenanceService = getIt<MaintenanceStateService>();
    final versionService = getIt<VersionCheckService>();

    try {
      final isMaintenance = await maintenanceService.isMaintenance();
      if (isMaintenance) {
        emit(SplashMaintenance());
        return;
      }

      final version = await versionService.check();
      if (version.forceUpdate) {
        emit(
          SplashForceUpdate(storeUrl: version.storeUrl, apkUrl: version.apkUrl),
        );
        return;
      }

      final token = await secureStorage.getToken();
      final logged = await secureStorage.getLoggedInStatus();

      if (token == null || token.isEmpty || !(logged ?? false)) {
        await secureStorage.deleteDynamicValue(
          AuthSessionService.pendingLogoutReasonKey,
        );
        emit(SplashUnauthenticated());
        return;
      }

      final role = await secureStorage.getRole();
      await authStorage.ensureSessionTypeFromRole(role);
      final isCitizen = role == 'CITIZEN';
      final now = DateTime.now();
      final lastOpenedAt = await authStorage.getLastOpenedAt();

      if (lastOpenedAt != null &&
          now.difference(lastOpenedAt) >= _sessionInactivityLimit) {
        await sessionService.clearSession(markSessionExpired: true);
        emit(SplashUnauthenticated());
        return;
      }

      await authStorage.setLastOpenedAt(now);

      // Lockable session — gate on local PIN before validating tokens.
      // We avoid touching the network while the app is locked.
      final isLockable = await authStorage.isAppLockSession();
      final pinSet = await authStorage.isPinSet();
      final refreshToken = await secureStorage.getRefreshToken();
      final hasRefresh = refreshToken != null && refreshToken.isNotEmpty;
      final requiresLockFlow = hasRefresh || isCitizen;

      if (isLockable && requiresLockFlow && pinSet && lockState.isLocked) {
        emit(SplashEmployeeLocked());
        return;
      }

      // Token still valid OR safely refreshed → proceed.
      // Timeout prevents indefinite hang when there is no network.
      final sessionResult = await sessionService.ensureValidSession().timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            const AuthSessionResult(status: AuthSessionStatus.unauthenticated),
      );
      if (!sessionResult.isAuthenticated) {
        emit(SplashUnauthenticated());
        return;
      }

      emit(
        SplashAuthenticated(
          isEmployee: sessionResult.isEmployee,
        ),
      );
    } catch (e) {
      AppLogger.error('SplashCubit auth bootstrap error: $e');
      emit(SplashUnauthenticated());
    }
  }
}

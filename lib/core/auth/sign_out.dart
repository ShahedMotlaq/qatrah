import 'package:qatrah/core/auth/app_lock_state.dart';
import 'package:qatrah/core/auth/auth_session_service.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/notification/notification_service.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/utils/app_logger.dart';
import 'package:qatrah/features/auth/domain/repositories/i_auth_repository.dart';

/// Ends the session: revoke server-side, then wipe local state.
///
/// Order matters. Revoking needs the refresh token, so it must happen *before*
/// storage is cleared — the settings page used to wipe storage first and the
/// refresh token was then never revoked server-side.
///
/// Nothing here may throw: every step is best-effort, because a user who taps
/// "sign out" must end up signed out locally even if the network is down.
/// Await this before navigating — the router guard reads the storage it clears.
Future<void> signOut({bool auto = false}) async {
  final secureStorage = getIt<SecureStorage>();
  final authStorage = getIt<SecureAuthStorage>();

  try {
    await secureStorage.addAuditLog(auto ? 'Auto logout' : 'User logout');
  } catch (e) {
    AppLogger.error('Logout audit failed: $e');
  }

  // Fire-and-forget the network leg: a server error must never block logout.
  try {
    await getIt<IAuthRepository>().logout(redirectUri: '');
  } catch (e) {
    AppLogger.error('Remote logout failed (continuing): $e');
  }

  await getIt<AuthSessionService>().clearSession();
  // Preserve PIN + biometric — the user can unlock again after re-login.
  await authStorage.clearForLogout();
  getIt<AppLockState>().markLocked();

  try {
    await getIt<NotificationService>().deleteTokenOnLogout();
  } catch (e) {
    AppLogger.error('FCM token delete on logout failed: $e');
  }
}

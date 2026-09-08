import 'dart:async';

import 'package:qatrah/core/auth/app_lock_state.dart';
import 'package:qatrah/core/auth/auth_session_service.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/notification/notification_service.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/utils/app_logger.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

// ── Section: Shared login plumbing ──────────────────────────────────────────
//
// There are four ways into the app — citizen password, employee password,
// citizen register, citizen OTP — and each had its own copy of the same
// post-login bookkeeping. They had already drifted apart: one reset the shared
// login-attempt counter that only another one enforces, one skipped the audit
// entry, and the OTP path reported a *successful* verification as failed if any
// of the bookkeeping threw. One implementation now, so they can't drift again.

enum LoginKind { citizen, employee }

/// Post-login bookkeeping. The token / role / refresh token are already stored
/// by the repository, so everything here is best-effort and merely logged on
/// failure — none of it may block a login the server has already accepted.
///
/// [rememberMe] of `null` leaves the stored preference untouched (the OTP flow
/// records the user's choice when the code is *sent*, before this runs).
///
/// Returns once the local state the router guard reads is consistent. The FCM
/// upload is deliberately not awaited: it is a network round-trip, and awaiting
/// it held the login button in limbo for seconds after the login had succeeded.
Future<void> completeLogin({
  required LoginKind kind,
  required String username,
  bool? rememberMe,
}) async {
  final storage = getIt<SecureStorage>();
  final isCitizen = kind == LoginKind.citizen;

  try {
    if (isCitizen) {
      // userName doubles as the display name elsewhere, so it is always kept;
      // the remember flag alone decides whether login prefills from it.
      await storage.setUserName(username);
      if (rememberMe != null) await storage.setCitizenRememberMe(rememberMe);
    } else {
      if (rememberMe == false) {
        await storage.deleteEmployeeUserName();
      } else {
        await storage.setEmployeeUserName(username);
      }
      if (rememberMe != null) await storage.setEmployeeRememberMe(rememberMe);
      // Only the employee login enforces the lockout, so only it clears the
      // counter. A citizen login used to reset it too, handing back five fresh
      // employee attempts.
      await storage.setLoginAttempts(0);
    }

    await storage.addAuditLog(
      '${isCitizen ? 'Citizen' : 'Employee'} login success: $username',
    );
    await getIt<SecureAuthStorage>().setSessionType(
      isCitizen ? 'otp' : 'keycloak',
    );
    await storage.deleteDynamicValue(AuthSessionService.pendingLogoutReasonKey);
  } catch (e) {
    AppLogger.error('Login bookkeeping failed: $e');
  }

  // Required before navigating: the router guard sends a locked session to the
  // PIN screen instead of the app.
  getIt<AppLockState>().markUnlocked();

  unawaited(
    getIt<NotificationService>().uploadTokenAfterLogin().catchError(
      (Object e) => AppLogger.error('FCM upload after login failed: $e'),
    ),
  );
}

/// Maps a repository failure code to a user-facing message.
String mapAuthError(String message, AppLocalizations l10n) {
  final normalized = message.trim().toLowerCase();
  if (normalized == 'error_invalid_credentials' || normalized.contains('401')) {
    return l10n.invalidCredentialsError;
  }
  if (normalized.contains('forbidden') || normalized.contains('403')) {
    return l10n.forbidden;
  }
  if (normalized == 'error_login') return l10n.errorLogin;
  if (normalized == 'error_fcm_update') return l10n.errorFcmUpdate;
  return message;
}

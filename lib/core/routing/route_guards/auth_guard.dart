import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/auth/app_lock_state.dart';
import 'package:qatrah/core/auth/auth_session_service.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/utils/app_logger.dart';

class AuthGuard {
  /// Routes that don't require any auth check at all.
  static const _publicRoutes = <String>{
    Routes.splash,
    Routes.login,
    Routes.loginPageEmployee,
    Routes.registerCitizen,
    Routes.otp,
    Routes.forceUpdate,
    Routes.maintenance,
  };

  /// Routes that are part of the local app-lock flow. They sit between
  /// "logged-in" and "fully unlocked" — no validate/refresh round-trip.
  static const _lockFlowRoutes = <String>{
    Routes.appLock,
    Routes.createPin,
    Routes.biometricSetup,
  };

  static Future<bool> _hasValidServerSession() async {
    try {
      final result = await getIt<AuthSessionService>().ensureValidSession();
      return result.isAuthenticated;
    } catch (e) {
      AppLogger.error('AuthGuard session check failed: $e');
      return false;
    }
  }

  /// The routing decision, with every storage/network read already resolved to
  /// a flag. Split out from [redirect] purely so it can be tested without a
  /// service locator — see test/core/routing/auth_guard_test.dart.
  ///
  /// [hasServerSession] is lazy: it is only awaited on paths that need it, so
  /// the lock flow still avoids the round-trip.
  static Future<String?> resolve({
    required String location,
    required bool hasLocalSession,
    required bool needsLock,
    required Future<bool> Function() hasServerSession,
  }) async {
    // Splash decides everything on cold start — never redirect away from it.
    if (location == Routes.splash) return null;

    final isPublic = _publicRoutes.contains(location);
    final isLockFlow = _lockFlowRoutes.contains(location);

    // Unauthenticated users can only see public routes. Hitting a lock-flow
    // route without a session is meaningless.
    if (!hasLocalSession) return isPublic ? null : Routes.login;

    if (needsLock) {
      if (location == Routes.appLock) return null;
      // Allow Forgot-PIN / login redirect to proceed.
      if (location == Routes.login) return null;
      return Routes.appLock;
    }

    // Lock-flow screens sit between "logged in" and "unlocked" — no
    // validate/refresh round-trip, and never bounced to navbar.
    if (isLockFlow) return null;

    // Past the lock flow, the stored token may still be expired. One
    // validation, and both branches below read the same answer.
    if (!await hasServerSession()) {
      // Storage is NOT always wiped on failure: on a network error the
      // credentials stay intact so the user can retry, which means
      // hasLocalSession is still true on the next pass. So a public route must
      // be allowed to render — returning navbar here bounced
      // login → navbar → login until go_router threw "too many redirects"
      // (a black screen, offline).
      return isPublic ? null : Routes.login;
    }

    // Fully authenticated user sitting on a public route → into the app.
    return isPublic ? Routes.navbar : null;
  }

  static Future<String?> redirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    // matchedLocation, not uri: uri carries query strings and would stop
    // `/login?foo=1` from matching the public-route set.
    final location = state.matchedLocation;
    if (location == Routes.splash) return null;

    final storage = getIt<SecureStorage>();
    final authStorage = getIt<SecureAuthStorage>();

    final token = await storage.getToken();
    final logged = await storage.getLoggedInStatus();
    final hasLocalSession =
        token != null && token.isNotEmpty && (logged ?? false);

    if (!hasLocalSession) {
      return resolve(
        location: location,
        hasLocalSession: false,
        needsLock: false,
        hasServerSession: () async => false,
      );
    }

    // We have a stored session. Decide whether the lock screen / pin setup
    // is still owed.
    final role = await storage.getRole();
    await authStorage.ensureSessionTypeFromRole(role);
    final refreshToken = await storage.getRefreshToken();
    final hasRefresh = refreshToken != null && refreshToken.isNotEmpty;

    final needsLock =
        await authStorage.isAppLockSession() &&
        (hasRefresh || role == 'CITIZEN') &&
        await authStorage.isPinSet() &&
        getIt<AppLockState>().isLocked;

    return resolve(
      location: location,
      hasLocalSession: true,
      needsLock: needsLock,
      hasServerSession: _hasValidServerSession,
    );
  }
}

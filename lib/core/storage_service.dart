// lib/core/storage_service.dart
//
// Unified session storage API per save_login.md spec.
// Wraps SecureStorage to provide atomic save/retrieve of the full login
// session (token, refresh token, expiry, user data, roles, flags).

import 'dart:convert';

import 'package:qatrah/core/auth/auth_session_service.dart'
    show AuthSessionService;
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/network/interceptors/auth_interceptor.dart'
    show AuthInterceptor;

/// Owns the unified login-session lifecycle: save, retrieve, validate, logout.
///
/// Built on top of [SecureStorage] so it reuses the existing DbKeys layer
/// and logging infrastructure.
class StorageService {
  StorageService(this._secureStorage);

  final SecureStorage _secureStorage;

  // ===========================================================================
  // 1. Save Login Session
  // ===========================================================================

  /// Persists the complete login session atomically.
  ///
  /// Call this once after a successful login/OTP verification so every
  /// piece of session data is written before the app proceeds.
  Future<void> saveLoginSession({
    required String token,
    required String userType,
    required Map<String, dynamic> userData,
    String? refreshToken,
    int? expiresIn,
    bool? roleAttendanceAdmin,
    bool? roleAttendanceObserver,
    bool? roleSuperAdminAttend,
  }) async {
    // 1. Access token (role-aware)
    await _secureStorage.setToken(token, role: userType);

    // 2. Refresh token
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.setRefreshToken(refreshToken);
    }

    // 3. Token expiry (now + expiresIn seconds)
    if (expiresIn != null) {
      final expiry = DateTime.now().add(Duration(seconds: expiresIn));
      await _secureStorage.setTokenExpiry(expiry);
    }

    // 4. User type & data
    await _secureStorage.setRole(userType);
    await _secureStorage.setUserData(jsonEncode(userData));

    // 5. Role flags
    if (roleAttendanceAdmin != null) {
      await _secureStorage.setRoleAttendanceAdmin(roleAttendanceAdmin);
    }
    if (roleAttendanceObserver != null) {
      await _secureStorage.setRoleAttendanceObserver(roleAttendanceObserver);
    }
    if (roleSuperAdminAttend != null) {
      await _secureStorage.setRoleSuperAdminAttend(roleSuperAdminAttend);
    }

    // 6. Logged-in flag
    await _secureStorage.setLoggedInStatus(true);
  }

  // ===========================================================================
  // 2. Retrieve Login Session
  // ===========================================================================

  /// Returns the full persisted session as a map.
  ///
  /// Returns `null` when any of the three core fields are missing
  /// (token, userType, userData), meaning the session is incomplete.
  Future<Map<String, dynamic>?> getLoginSession() async {
    final token = await _secureStorage.getToken();
    final userType = await _secureStorage.getRole();
    final userDataRaw = await _secureStorage.getUserData();

    // Core fields must exist for a valid session
    if (token == null || token.isEmpty) return null;
    if (userType == null || userType.isEmpty) return null;
    if (userDataRaw == null || userDataRaw.isEmpty) return null;

    Map<String, dynamic>? userData;
    try {
      userData = jsonDecode(userDataRaw) as Map<String, dynamic>;
    } catch (_) {
      userData = null;
    }

    return {
      'token': token,
      'refresh_token': await _secureStorage.getRefreshToken(),
      'token_expiry': (await _secureStorage.getTokenExpiry())
          ?.toIso8601String(),
      'user_type': userType,
      'user_data': userData,
      'role_attendance_admin': await _secureStorage.getRoleAttendanceAdmin(),
      'role_attendance_observer': await _secureStorage
          .getRoleAttendanceObserver(),
      'role_super_admin_attend': await _secureStorage.getRoleSuperAdminAttend(),
    };
  }

  // ===========================================================================
  // 3. Session validation
  // ===========================================================================

  /// Quick check: does a token + role + userData exist?
  ///
  /// **Note:** This does *not* verify JWT expiration. The [AuthSessionService]
  /// and [AuthInterceptor] handle expiry/refresh automatically.
  Future<bool> hasValidSession() async {
    final token = await _secureStorage.getToken();
    final role = await _secureStorage.getRole();
    final userData = await _secureStorage.getUserData();
    final loggedIn = await _secureStorage.getLoggedInStatus();

    return token != null &&
        token.isNotEmpty &&
        role != null &&
        role.isNotEmpty &&
        userData != null &&
        userData.isNotEmpty &&
        (loggedIn ?? false);
  }

  // ===========================================================================
  // 4. Logout (preserve device data)
  // ===========================================================================

  /// Clears user-session keys but **preserves** device-level keys
  /// (FCM token, device ID, locale, PIN/biometric settings, etc.).
  ///
  /// Use this for normal logout.
  Future<void> logout() async {
    await _secureStorage.clearAuth();
  }

  // ===========================================================================
  // 5. Clear All (nuclear option)
  // ===========================================================================

  /// Deletes **everything** in secure storage, including device-level keys.
  ///
  /// Use this only for:
  /// - Fresh-install wipe
  /// - Forgot-PIN / credential reset
  /// - Debug / testing reset
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}

import 'package:qatrah/core/local_storage/secure_storage.dart';

/// Owns the new auth-lock storage keys (PIN hash/salt, lockout state,
/// biometric flag, session-type, last-backgrounded marker).
///
/// Built on top of [SecureStorage] using its dynamic key APIs so we don't
/// need to extend the existing [DbKeys] enum. Existing tokens / role / user
/// keys keep their original [DbKeys] entries.
class SecureAuthStorage {
  SecureAuthStorage(this._storage);

  final SecureStorage _storage;

  // ---- Keys (centralized) ----------------------------------------------------
  static const _kSessionType = 'auth.session_type';
  static const _kPinHash = 'auth.pin_hash';
  static const _kPinSalt = 'auth.pin_salt';
  static const _kPinIterations = 'auth.pin_iterations';
  static const _kPinSet = 'auth.pin_set';
  static const _kBiometricEnabled = 'auth.biometric_enabled';
  static const _kPinFailedCount = 'auth.pin_failed_count';
  static const _kPinLockUntilMs = 'auth.pin_lock_until_ms';
  static const _kLastBackgroundedAtMs = 'auth.last_backgrounded_at_ms';
  static const _kLastOpenedAtMs = 'auth.last_opened_at_ms';

  /// All keys this service writes — used by the fresh-install marker to wipe
  /// a stale Keychain (iOS Keychain survives reinstall) without touching
  /// unrelated user prefs.
  static const List<String> allKeys = <String>[
    _kSessionType,
    _kPinHash,
    _kPinSalt,
    _kPinIterations,
    _kPinSet,
    _kBiometricEnabled,
    _kPinFailedCount,
    _kPinLockUntilMs,
    _kLastBackgroundedAtMs,
    _kLastOpenedAtMs,
  ];

  // ---- Session type ---------------------------------------------------------
  /// [staffSession] for operator/admin, [citizenSession] for citizen.
  static const String staffSession = 'staff';
  static const String citizenSession = 'citizen';

  /// Values written by builds that signed staff in through Keycloak and
  /// citizens through OTP. Both now use `POST /auth/login`, so the labels are
  /// migrated on read — see [getSessionType].
  static const Map<String, String> _legacySessionTypes = <String, String>{
    'keycloak': staffSession,
    'otp': citizenSession,
  };

  /// Storage key of the Keycloak role cache that older builds wrote. Nothing
  /// reads it any more; it is deleted when a legacy session is migrated.
  static const String _kLegacyKeycloakRoles = 'keycloakRoles';

  Future<void> setSessionType(String type) =>
      _storage.setDynamicValue(_kSessionType, type);

  /// Reads the session type, rewriting a legacy label in place the first time
  /// it is seen. Self-healing, so no startup migration hook is needed.
  Future<String?> getSessionType() async {
    final raw = await _storage.getDynamicValue(_kSessionType);
    final migrated = _legacySessionTypes[raw];
    if (migrated == null) return raw;

    await _storage.setDynamicValue(_kSessionType, migrated);
    await _storage.deleteDynamicValue(_kLegacyKeycloakRoles);
    return migrated;
  }

  Future<bool> isStaffSession() async =>
      (await getSessionType()) == staffSession;

  Future<bool> isCitizenSession() async =>
      (await getSessionType()) == citizenSession;

  /// Sessions that should use the app-lock (PIN/biometric) flow.
  Future<bool> isAppLockSession() async {
    final type = await getSessionType();
    return type == staffSession || type == citizenSession;
  }

  /// Ensure a session type exists for legacy sessions that predate the key.
  /// Returns the resolved session type (or null if role is unknown).
  Future<String?> ensureSessionTypeFromRole(String? role) async {
    final current = await getSessionType();
    if (current != null && current.isNotEmpty) return current;
    if (role == null || role.isEmpty) return null;

    // A session this old may also carry the dead Keycloak role cache.
    await _storage.deleteDynamicValue(_kLegacyKeycloakRoles);

    if (role == 'EMPLOYEE' || role == 'ADMIN' || role == 'OPERATOR') {
      await setSessionType(staffSession);
      return staffSession;
    }
    if (role == 'CITIZEN') {
      await setSessionType(citizenSession);
      return citizenSession;
    }
    return null;
  }

  // ---- PIN material ---------------------------------------------------------
  Future<void> savePinMaterial({
    required String hashBase64,
    required String saltBase64,
    required int iterations,
  }) async {
    await _storage.setDynamicValue(_kPinHash, hashBase64);
    await _storage.setDynamicValue(_kPinSalt, saltBase64);
    await _storage.setDynamicValue(_kPinIterations, iterations.toString());
    await _storage.setDynamicBoolValue(_kPinSet, true);
  }

  Future<String?> getPinHash() => _storage.getDynamicValue(_kPinHash);
  Future<String?> getPinSalt() => _storage.getDynamicValue(_kPinSalt);

  Future<int?> getPinIterations() async {
    final raw = await _storage.getDynamicValue(_kPinIterations);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<bool> isPinSet() async =>
      (await _storage.getDynamicBoolValue(_kPinSet)) ?? false;

  Future<void> clearPinMaterial() async {
    await _storage.deleteDynamicValue(_kPinHash);
    await _storage.deleteDynamicValue(_kPinSalt);
    await _storage.deleteDynamicValue(_kPinIterations);
    await _storage.deleteDynamicValue(_kPinSet);
    await resetFailedAttempts();
  }

  // ---- Biometric ------------------------------------------------------------
  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.setDynamicBoolValue(_kBiometricEnabled, enabled);

  Future<bool> isBiometricEnabled() async =>
      (await _storage.getDynamicBoolValue(_kBiometricEnabled)) ?? false;

  // ---- Failed attempts / lockout -------------------------------------------
  Future<int> getFailedAttempts() async {
    final raw = await _storage.getDynamicValue(_kPinFailedCount);
    if (raw == null) return 0;
    return int.tryParse(raw) ?? 0;
  }

  Future<void> setFailedAttempts(int count) =>
      _storage.setDynamicValue(_kPinFailedCount, count.toString());

  Future<void> resetFailedAttempts() async {
    await _storage.deleteDynamicValue(_kPinFailedCount);
    await _storage.deleteDynamicValue(_kPinLockUntilMs);
  }

  Future<DateTime?> getLockUntil() async {
    final raw = await _storage.getDynamicValue(_kPinLockUntilMs);
    if (raw == null) return null;
    final ms = int.tryParse(raw);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLockUntil(DateTime? time) async {
    if (time == null) {
      await _storage.deleteDynamicValue(_kPinLockUntilMs);
    } else {
      await _storage.setDynamicValue(
        _kPinLockUntilMs,
        time.millisecondsSinceEpoch.toString(),
      );
    }
  }

  // ---- Background timestamp -------------------------------------------------
  Future<void> setLastBackgroundedAt(DateTime time) => _storage.setDynamicValue(
    _kLastBackgroundedAtMs,
    time.millisecondsSinceEpoch.toString(),
  );

  Future<DateTime?> getLastBackgroundedAt() async {
    final raw = await _storage.getDynamicValue(_kLastBackgroundedAtMs);
    if (raw == null) return null;
    final ms = int.tryParse(raw);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> clearLastBackgroundedAt() =>
      _storage.deleteDynamicValue(_kLastBackgroundedAtMs);

  // ---- Last opened timestamp -----------------------------------------------
  Future<void> setLastOpenedAt(DateTime time) => _storage.setDynamicValue(
    _kLastOpenedAtMs,
    time.millisecondsSinceEpoch.toString(),
  );

  Future<DateTime?> getLastOpenedAt() async {
    final raw = await _storage.getDynamicValue(_kLastOpenedAtMs);
    if (raw == null) return null;
    final ms = int.tryParse(raw);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Clears session data on normal logout but preserves PIN and biometric
  /// settings so the user can unlock again after re-login.
  ///
  /// Use [clear] only when the user explicitly resets credentials (forgot PIN).
  Future<void> clearForLogout() async {
    await _storage.deleteDynamicValue(_kSessionType);
    await _storage.deleteDynamicValue(_kPinFailedCount);
    await _storage.deleteDynamicValue(_kPinLockUntilMs);
    await _storage.deleteDynamicValue(_kLastBackgroundedAtMs);
    await _storage.deleteDynamicValue(_kLastOpenedAtMs);
  }

  /// Wipe everything this service owns. Does NOT touch tokens or unrelated
  /// preferences — those are handled by the existing [SecureStorage.clearAuth].
  Future<void> clear() async {
    for (final key in allKeys) {
      await _storage.deleteDynamicValue(key);
    }
  }
}

import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Detects a fresh install and purges only auth/security secure-storage keys.
///
/// Why: on iOS, secure storage (Keychain) survives app uninstall. Without
/// this marker, an attacker could reinstall the app and find a still-valid
/// auth session. On Android with `allowBackup="false"` plus this marker we
/// also defend against backup-and-restore reuse.
///
/// We do NOT call `secureStorage.clearAuth()` blindly because that would
/// also delete locale/etc. Instead we touch just the auth + security keys.
class FreshInstallMarker {
  FreshInstallMarker(this._secureStorage, this._authStorage);

  final SecureStorage _secureStorage;
  final SecureAuthStorage _authStorage;

  static const String _markerKey = 'auth.install_marker';
  static const String _legacyPinPurgedKey = 'auth.legacy_pin_purged';

  Future<void> ensureMarker() async {
    final prefs = await SharedPreferences.getInstance();
    final exists = prefs.getBool(_markerKey) ?? false;
    if (exists) return;

    await _purgeAuthKeys();
    await prefs.setBool(_markerKey, true);
  }

  /// One-time purge of legacy plaintext PIN material for users upgrading the
  /// app in place. [ensureMarker] only purges on a *fresh* install (its marker
  /// is already set for upgraders), so without this a stale plaintext PIN
  /// written by an older build would linger in secure storage indefinitely.
  ///
  /// Idempotent and gated by its own flag, so it touches the keychain at most
  /// once. We purge rather than port: the hashed flow (SecureAuthStorage +
  /// PinSecurityService) is the single source of truth, and the user simply
  /// re-creates their PIN through it.
  Future<void> ensureLegacyPinPurged() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_legacyPinPurgedKey) ?? false) return;

    await _secureStorage.purgeLegacyPlaintextPin();
    await prefs.setBool(_legacyPinPurgedKey, true);
  }

  Future<void> _purgeAuthKeys() async {
    // Existing typed auth keys.
    await _secureStorage.deleteValue(DbKeys.token);
    await _secureStorage.deleteValue(DbKeys.employeeToken);
    await _secureStorage.deleteValue(DbKeys.citizenToken);
    await _secureStorage.deleteValue(DbKeys.refreshToken);
    await _secureStorage.deleteValue(DbKeys.role);
    await _secureStorage.deleteValue(DbKeys.username);
    await _secureStorage.deleteValue(DbKeys.citizenPhone);
    await _secureStorage.deleteValue(DbKeys.employeeUsername);
    await _secureStorage.deleteValue(DbKeys.rememberMe);
    await _secureStorage.deleteValue(DbKeys.citizenRememberMe);
    await _secureStorage.deleteValue(DbKeys.employeeRememberMe);
    await _secureStorage.deleteValue(DbKeys.assignedUnitIds);
    await _secureStorage.deleteValue(DbKeys.assignedRegionIds);
    await _secureStorage.deleteValue(DbKeys.loginAttempts);
    await _secureStorage.deleteValue(DbKeys.lockoutUntil);
    await _secureStorage.deleteValue(DbKeys.logged);

    // Legacy plaintext PIN keys (removed from DbKeys). Purged so a stale
    // plaintext PIN written by an older app version cannot survive a reinstall
    // (iOS Keychain outlives uninstall).
    await _secureStorage.purgeLegacyPlaintextPin();

    // New auth-lock keys.
    await _authStorage.clear();
  }
}

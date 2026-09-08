import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qatrah/core/utils/app_logger.dart';

enum DbKeys {
  username,
  citizenPhone,
  employeeUsername,
  token, // Legacy key, kept for backward compatibility
  employeeToken, // Role-isolated token for employees
  citizenToken, // Role-isolated token for citizens
  refreshToken,
  role,
  admin,
  premium,
  logged,
  local,
  firstOpen,
  loginAttempts,
  lockoutUntil,
  auditLog,
  rememberMe,
  citizenRememberMe,
  employeeRememberMe,
  regionId,
  unitId,
  neighborhoodId,
  zoneId,
  assignedUnitIds, // Comma-separated list of unit IDs assigned to operator
  assignedRegionIds, // Comma-separated list of region IDs assigned to employee
  tokenExpiry, // Access token expiration timestamp (ISO-8601)
  userData, // JSON-encoded user data
  keycloakRoles, // JSON-encoded Keycloak roles list
  roleAttendanceAdmin, // Role flag: attendance admin
  roleAttendanceObserver, // Role flag: attendance observer
  roleSuperAdminAttend, // Role flag: super admin attend
  selectedHomeAddressId,
  selectedHomeRegionId,
  selectedHomeUnitId,
  selectedHomeNeighborhoodId,
  selectedHomeZoneId,
  selectedHomeLocationName,
  otpBlockEndTime,
  otpRetryLevel,
}

class SecureStorage {
  SecureStorage([
    FlutterSecureStorage? storage,
    bool? enableLogs,
  ]) : _storage = storage ?? const FlutterSecureStorage(),
       _enableLogs = enableLogs ?? kDebugMode;

  final FlutterSecureStorage _storage;

  /// Enable/disable logs (defaults to kDebugMode)
  final bool _enableLogs;

  // -----------------------------
  // Logging helpers
  // -----------------------------
  bool _isSensitive(DbKeys key) {
    return key == DbKeys.token ||
        key == DbKeys.employeeToken ||
        key == DbKeys.citizenToken ||
        key == DbKeys.refreshToken;
  }

  String _maskValue(String? value) {
    if (value == null) return 'null';
    if (value.isEmpty) return '(empty)';
    if (value.length <= 6) return '***';
    return '${value.substring(0, 3)}***${value.substring(value.length - 3)}';
  }

  void _logStart(String opName, {DbKeys? key, String? value}) {
    if (!_enableLogs) return;
    final keyLabel = key?.name ?? '-';
    final safeValue = key != null && _isSensitive(key)
        ? _maskValue(value)
        : (value ?? '-');

    // Choose color by operation
    switch (opName) {
      case 'READ':
        AppLogger.enabled = _enableLogs;
        AppLogger.read('START | key=$keyLabel | value=$safeValue');
      case 'WRITE':
        AppLogger.enabled = _enableLogs;
        AppLogger.write('START | key=$keyLabel | value=$safeValue');
      case 'DELETE':
      case 'DELETE_ALL':
        AppLogger.enabled = _enableLogs;
        AppLogger.delete('START $opName | key=$keyLabel');
      case 'AUDIT':
        AppLogger.enabled = _enableLogs;
        AppLogger.audit('START | key=$keyLabel');
      default:
        AppLogger.enabled = _enableLogs;
        AppLogger.info('START $opName | key=$keyLabel | value=$safeValue');
    }
  }

  void _logOk(String opName, {DbKeys? key, String? returned}) {
    if (!_enableLogs) return;
    final keyLabel = key?.name ?? '-';

    if (opName == 'READ') {
      final safeReturned = key != null && _isSensitive(key)
          ? _maskValue(returned)
          : (returned ?? 'null');
      AppLogger.enabled = _enableLogs;
      AppLogger.read('OK   | key=$keyLabel | returned=$safeReturned');
      return;
    }

    switch (opName) {
      case 'WRITE':
        AppLogger.enabled = _enableLogs;
        AppLogger.write('OK   | key=$keyLabel');
      case 'DELETE':
      case 'DELETE_ALL':
        AppLogger.enabled = _enableLogs;
        AppLogger.delete('OK   $opName | key=$keyLabel');
      default:
        AppLogger.enabled = _enableLogs;
        AppLogger.info('OK   $opName | key=$keyLabel');
    }
  }

  void _logFail(String opName, {DbKeys? key, Object? error, StackTrace? st}) {
    if (!_enableLogs) return;
    final keyLabel = key?.name ?? '-';
    AppLogger.enabled = _enableLogs;
    AppLogger.error('FAIL $opName | key=$keyLabel | error=$error');
    if (st != null) AppLogger.error(st.toString());
  }

  Future<T?> _performOperation<T>(
    String opName, {
    required Future<T?> Function() operation,
    DbKeys? key,
    String? value,
  }) async {
    _logStart(opName, key: key, value: value);

    try {
      final result = await operation();

      if (opName == 'READ') {
        _logOk(opName, key: key, returned: result as String?);
      } else {
        _logOk(opName, key: key);
      }

      return result;
    } catch (e, st) {
      _logFail(opName, key: key, error: e, st: st);
      // Return exception instead of null for storage errors
      rethrow;
    }
  }

  // -----------------------------
  // Core operations
  // -----------------------------
  Future<void> setValue(DbKeys key, String value) async {
    await _performOperation<void>(
      'WRITE',
      key: key,
      value: value,
      operation: () async {
        await _storage.write(key: key.name, value: value);
        return;
      },
    );
  }

  Future<String?> getValue(DbKeys key) async {
    return _performOperation<String>(
      'READ',
      key: key,
      operation: () => _storage.read(key: key.name),
    );
  }

  Future<void> deleteValue(DbKeys key) async {
    await _performOperation<void>(
      'DELETE',
      key: key,
      operation: () async {
        await _storage.delete(key: key.name);
        return;
      },
    );
  }

  Future<void> deleteAll() async {
    await _performOperation<void>(
      'DELETE_ALL',
      operation: () async {
        await _storage.deleteAll();
        return;
      },
    );
  }

  // -----------------------------
  // Convenience methods
  // -----------------------------
  Future<void> setBoolValue(DbKeys key, bool value) async {
    await setValue(key, value.toString());
  }

  Future<bool?> getBoolValue(DbKeys key) async {
    final value = await getValue(key);
    return value != null ? value.toLowerCase() == 'true' : null;
  }

  Future<void> setFirstOpenStatus(bool isFirstOpen) =>
      setBoolValue(DbKeys.firstOpen, isFirstOpen);

  Future<bool?> getFirstOpenStatus() => getBoolValue(DbKeys.firstOpen);

  Future<void> setLocalizedValue(String languageCode) =>
      setValue(DbKeys.local, languageCode);

  Future<String?> getLocalizedValue() => getValue(DbKeys.local);

  Future<void> setAdminStatus(bool isAdmin) =>
      setBoolValue(DbKeys.admin, isAdmin);

  Future<bool?> getAdminStatus() => getBoolValue(DbKeys.admin);

  Future<void> setPremiumStatus(bool isPremium) =>
      setBoolValue(DbKeys.premium, isPremium);

  Future<bool?> getPremiumStatus() => getBoolValue(DbKeys.premium);

  Future<void> setLoggedInStatus(bool isLoggedIn) =>
      setBoolValue(DbKeys.logged, isLoggedIn);

  Future<bool?> getLoggedInStatus() => getBoolValue(DbKeys.logged);

  Future<void> setUserName(String username) =>
      setValue(DbKeys.username, username);

  Future<String?> getUserName() => getValue(DbKeys.username);

  Future<void> setCitizenPhone(String phone) =>
      setValue(DbKeys.citizenPhone, phone);

  Future<String?> getCitizenPhone() => getValue(DbKeys.citizenPhone);

  Future<void> deleteCitizenPhone() => deleteValue(DbKeys.citizenPhone);

  Future<void> setEmployeeUserName(String username) =>
      setValue(DbKeys.employeeUsername, username);

  Future<String?> getEmployeeUserName() => getValue(DbKeys.employeeUsername);

  Future<void> deleteEmployeeUserName() => deleteValue(DbKeys.employeeUsername);

  /// Set token with strict awaiting to prevent race conditions.
  /// Uses role-based keys to prevent overwriting between employee/citizen
  /// sessions. The token is written to a single slot only — the role-specific
  /// key when the role is known, otherwise the legacy [DbKeys.token] slot.
  Future<void> setToken(String token, {String? role}) async {
    final key = _getTokenKeyForRole(role);
    await setValue(key, token);

    // We no longer mirror the token into the legacy [DbKeys.token] key. When
    // we just wrote a role-specific key, drop any pre-existing legacy copy so
    // a later role-less read can never resurrect a stale token. (Migrated
    // sessions that still only have the legacy copy are handled by getToken.)
    if (key != DbKeys.token) {
      await deleteValue(DbKeys.token);
    }
  }

  /// Get token with role awareness. If no role specified, tries to get stored
  /// role first.
  Future<String?> getToken({String? role}) async {
    final effectiveRole = role ?? await getRole();

    final key = _getTokenKeyForRole(effectiveRole);
    final roleToken = await getValue(key);
    if (roleToken != null && roleToken.isNotEmpty) {
      return roleToken;
    }

    // The resolved key was empty. This happens when the role is momentarily
    // null/desynced relative to a still-valid session, or for a session
    // migrated from an older build that only wrote the legacy [DbKeys.token].
    // Probe the remaining slots — role-specific keys first, legacy last — so
    // we recover the live token without depending on a mirrored copy.
    for (final fallbackKey in const [
      DbKeys.employeeToken,
      DbKeys.citizenToken,
      DbKeys.token,
    ]) {
      if (fallbackKey == key) continue;
      final fallbackToken = await getValue(fallbackKey);
      if (fallbackToken != null && fallbackToken.isNotEmpty) {
        // Safe diagnostic (READ-ONLY — never changes which token is returned):
        // surfacing the rescue lets us confirm in the field whether the
        // role-desync race ever actually fires.
        AppLogger.enabled = _enableLogs;
        AppLogger.read(
          'TOKEN fallback | role-key=${key.name} empty for '
          'role="${effectiveRole ?? '<null>'}" — served ${fallbackKey.name}. '
          'If role should be non-null here, a state/storage desync occurred.',
        );
        return fallbackToken;
      }
    }

    return null;
  }

  /// Delete tokens for specific role or all tokens
  Future<void> deleteToken({String? role}) async {
    if (role == null) {
      await deleteValue(DbKeys.employeeToken);
      await deleteValue(DbKeys.citizenToken);
    } else {
      final key = _getTokenKeyForRole(role);
      await deleteValue(key);
    }
    await deleteValue(DbKeys.token);
  }

  /// Determine which token key to use based on role
  DbKeys _getTokenKeyForRole(String? role) {
    if (role == 'EMPLOYEE' || role == 'ADMIN' || role == 'OPERATOR') {
      return DbKeys.employeeToken;
    }
    if (role == 'CITIZEN') {
      return DbKeys.citizenToken;
    }
    // Default to legacy key for unknown roles
    return DbKeys.token;
  }

  Future<void> setRefreshToken(String refreshToken) =>
      setValue(DbKeys.refreshToken, refreshToken);

  Future<String?> getRefreshToken() => getValue(DbKeys.refreshToken);

  // ---- Token expiry ---------------------------------------------------------
  Future<void> setTokenExpiry(DateTime expiry) =>
      setValue(DbKeys.tokenExpiry, expiry.toIso8601String());

  Future<DateTime?> getTokenExpiry() async {
    final value = await getValue(DbKeys.tokenExpiry);
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> clearTokenExpiry() => deleteValue(DbKeys.tokenExpiry);

  // ---- User data ------------------------------------------------------------
  Future<void> setUserData(String jsonUserData) =>
      setValue(DbKeys.userData, jsonUserData);

  Future<String?> getUserData() => getValue(DbKeys.userData);

  Future<void> clearUserData() => deleteValue(DbKeys.userData);

  // ---- Keycloak roles -------------------------------------------------------
  Future<void> setKeycloakRoles(String jsonRoles) =>
      setValue(DbKeys.keycloakRoles, jsonRoles);

  Future<String?> getKeycloakRoles() => getValue(DbKeys.keycloakRoles);

  Future<void> clearKeycloakRoles() => deleteValue(DbKeys.keycloakRoles);

  // ---- Role flags -----------------------------------------------------------
  Future<void> setRoleAttendanceAdmin(bool value) =>
      setBoolValue(DbKeys.roleAttendanceAdmin, value);

  Future<bool?> getRoleAttendanceAdmin() =>
      getBoolValue(DbKeys.roleAttendanceAdmin);

  Future<void> setRoleAttendanceObserver(bool value) =>
      setBoolValue(DbKeys.roleAttendanceObserver, value);

  Future<bool?> getRoleAttendanceObserver() =>
      getBoolValue(DbKeys.roleAttendanceObserver);

  Future<void> setRoleSuperAdminAttend(bool value) =>
      setBoolValue(DbKeys.roleSuperAdminAttend, value);

  Future<bool?> getRoleSuperAdminAttend() =>
      getBoolValue(DbKeys.roleSuperAdminAttend);

  Future<void> setRole(String role) => setValue(DbKeys.role, role);

  Future<String?> getRole() => getValue(DbKeys.role);

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    final ok = token != null && token.isNotEmpty;
    if (_enableLogs) {
      AppLogger.enabled = _enableLogs;
      AppLogger.info('CHECK isAuthenticated => $ok');
    }
    return ok;
  }

  Future<void> clearAuth() async {
    if (_enableLogs) {
      AppLogger.enabled = _enableLogs;
      AppLogger.delete('CLEAR_AUTH start');
    }
    await deleteToken(); // Deletes all role-specific tokens + legacy
    await deleteValue(DbKeys.refreshToken);
    await deleteValue(DbKeys.username);
    await deleteValue(DbKeys.citizenPhone);
    await deleteValue(DbKeys.employeeUsername);
    await deleteValue(DbKeys.role);
    await deleteValue(DbKeys.rememberMe);
    await deleteValue(DbKeys.citizenRememberMe);
    await deleteValue(DbKeys.employeeRememberMe);
    await deleteValue(DbKeys.assignedUnitIds);
    await deleteValue(DbKeys.assignedRegionIds);
    await clearSelectedHomeAddress();
    await setLoggedInStatus(false);
    await clearTokenExpiry();
    await clearUserData();
    await clearKeycloakRoles();
    await deleteValue(DbKeys.roleAttendanceAdmin);
    await deleteValue(DbKeys.roleAttendanceObserver);
    await deleteValue(DbKeys.roleSuperAdminAttend);
    if (_enableLogs) {
      AppLogger.enabled = _enableLogs;
      AppLogger.delete('CLEAR_AUTH done');
    }
  }

  /// Purge legacy plaintext PIN keys written by app versions that predate the
  /// hashed PIN flow (SecureAuthStorage + PinSecurityService). These keys were
  /// removed from [DbKeys], so they are deleted by their original raw storage
  /// names. Idempotent — safe to call when the keys are already absent.
  ///
  /// PIN verification now lives entirely in the hashed store; nothing reads
  /// these keys anymore, so removing them eliminates the last place a PIN
  /// could sit in plaintext.
  Future<void> purgeLegacyPlaintextPin() async {
    await deleteDynamicValue('pinCode');
    await deleteDynamicValue('pinVerified');
  }

  Future<bool> containsKey(DbKeys key) async {
    final res =
        await _performOperation<bool>(
          'CONTAINS_KEY',
          key: key,
          operation: () {
            return _storage.containsKey(key: key.name);
          },
        ) ??
        false;

    if (_enableLogs) {
      AppLogger.enabled = _enableLogs;
      AppLogger.info('CONTAINS_KEY | key=${key.name} => $res');
    }
    return res;
  }

  Future<Map<String, String>> getAllKeys() async {
    final res =
        await _performOperation<Map<String, String>>(
          'READ_ALL',
          operation: _storage.readAll,
        ) ??
        {};

    if (_enableLogs) {
      AppLogger.enabled = _enableLogs;
      AppLogger.info('READ_ALL count=${res.length}');
    }
    return res;
  }

  Future<void> setLoginAttempts(int attempts) async {
    await setValue(DbKeys.loginAttempts, attempts.toString());
  }

  Future<int> getLoginAttempts() async {
    final value = await getValue(DbKeys.loginAttempts);
    final n = value != null ? int.tryParse(value) ?? 0 : 0;

    if (_enableLogs) {
      AppLogger.enabled = _enableLogs;
      AppLogger.read('loginAttempts => $n');
    }
    return n;
  }

  Future<void> setLockoutUntil(DateTime time) async {
    await setValue(DbKeys.lockoutUntil, time.toIso8601String());
  }

  Future<DateTime?> getLockoutUntil() async {
    final value = await getValue(DbKeys.lockoutUntil);
    final t = value != null ? DateTime.tryParse(value) : null;

    if (_enableLogs) {
      AppLogger.enabled = _enableLogs;
      AppLogger.read('lockoutUntil => ${t?.toIso8601String() ?? "null"}');
    }
    return t;
  }

  Future<void> addAuditLog(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp] $message';

    if (_enableLogs) {
      AppLogger.enabled = _enableLogs;
      AppLogger.audit('add => $message');
    }

    final existing = await getValue(DbKeys.auditLog);
    final updated = existing == null ? entry : '$existing\n$entry';

    await setValue(DbKeys.auditLog, updated);
  }

  Future<String?> getAuditLog() async {
    return getValue(DbKeys.auditLog);
  }

  Future<void> clearAuditLog() async {
    if (_enableLogs) {
      AppLogger.enabled = _enableLogs;
      AppLogger.audit('clear');
    }
    await deleteValue(DbKeys.auditLog);
  }

  // Add these methods to the SecureStorage class

  /// Set dynamic string value (for caching)
  Future<void> setDynamicValue(String key, String value) async {
    await _performOperation<void>(
      'WRITE',
      value: value,
      operation: () async {
        await _storage.write(key: key, value: value);
        return;
      },
    );
  }

  /// Get dynamic string value
  Future<String?> getDynamicValue(String key) async {
    return _performOperation<String>(
      'READ',
      operation: () => _storage.read(key: key),
    );
  }

  /// Set dynamic boolean value
  Future<void> setDynamicBoolValue(String key, bool value) async {
    await setDynamicValue(key, value.toString());
  }

  /// Get dynamic boolean value
  Future<bool?> getDynamicBoolValue(String key) async {
    final value = await getDynamicValue(key);
    return value != null ? value.toLowerCase() == 'true' : null;
  }

  /// Delete dynamic value
  Future<void> deleteDynamicValue(String key) async {
    await _performOperation<void>(
      'DELETE',
      operation: () async {
        await _storage.delete(key: key);
        return;
      },
    );
  }

  Future<void> printAllKeys() async {
    final all = await getAllKeys();
    print('📦 SecureStorage Keys: ${all.keys}');
    for (final entry in all.entries) {
      print('   🔑 ${entry.key}: ${entry.value}');
    }
  }

  Future<void> setRememberMe(bool value) =>
      setBoolValue(DbKeys.rememberMe, value);

  Future<bool?> getRememberMe() => getBoolValue(DbKeys.rememberMe);

  Future<void> setCitizenRememberMe(bool value) =>
      setBoolValue(DbKeys.citizenRememberMe, value);

  Future<bool?> getCitizenRememberMe() =>
      getBoolValue(DbKeys.citizenRememberMe);

  Future<void> setEmployeeRememberMe(bool value) =>
      setBoolValue(DbKeys.employeeRememberMe, value);

  Future<bool?> getEmployeeRememberMe() =>
      getBoolValue(DbKeys.employeeRememberMe);

  Future<void> setSelectedHomeAddress({
    required int addressId,
    required int regionId,
    required int unitId,
    required int neighborhoodId,
    required int zoneId,
    required String locationName,
  }) async {
    await setValue(DbKeys.selectedHomeAddressId, addressId.toString());
    await setValue(DbKeys.selectedHomeRegionId, regionId.toString());
    await setValue(DbKeys.selectedHomeUnitId, unitId.toString());
    await setValue(
      DbKeys.selectedHomeNeighborhoodId,
      neighborhoodId.toString(),
    );
    await setValue(DbKeys.selectedHomeZoneId, zoneId.toString());
    await setValue(DbKeys.selectedHomeLocationName, locationName);
  }

  Future<int?> getSelectedHomeAddressId() async {
    final value = await getValue(DbKeys.selectedHomeAddressId);
    return int.tryParse(value ?? '');
  }

  Future<int?> getSelectedHomeRegionId() async {
    final value = await getValue(DbKeys.selectedHomeRegionId);
    return int.tryParse(value ?? '');
  }

  Future<int?> getSelectedHomeUnitId() async {
    final value = await getValue(DbKeys.selectedHomeUnitId);
    return int.tryParse(value ?? '');
  }

  Future<int?> getSelectedHomeNeighborhoodId() async {
    final value = await getValue(DbKeys.selectedHomeNeighborhoodId);
    return int.tryParse(value ?? '');
  }

  Future<int?> getSelectedHomeZoneId() async {
    final value = await getValue(DbKeys.selectedHomeZoneId);
    return int.tryParse(value ?? '');
  }

  Future<String?> getSelectedHomeLocationName() =>
      getValue(DbKeys.selectedHomeLocationName);

  Future<void> clearSelectedHomeAddress() async {
    await deleteValue(DbKeys.selectedHomeAddressId);
    await deleteValue(DbKeys.selectedHomeRegionId);
    await deleteValue(DbKeys.selectedHomeUnitId);
    await deleteValue(DbKeys.selectedHomeNeighborhoodId);
    await deleteValue(DbKeys.selectedHomeZoneId);
    await deleteValue(DbKeys.selectedHomeLocationName);
  }

  Future<void> setOtpBlockEndTime(DateTime endTime) =>
      setValue(DbKeys.otpBlockEndTime, endTime.toIso8601String());

  Future<DateTime?> getOtpBlockEndTime() async {
    final value = await getValue(DbKeys.otpBlockEndTime);
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setOtpRetryLevel(int level) =>
      setValue(DbKeys.otpRetryLevel, level.toString());

  Future<int> getOtpRetryLevel() async {
    final value = await getValue(DbKeys.otpRetryLevel);
    return int.tryParse(value ?? '') ?? 0;
  }

  Future<void> clearOtpBlock() async {
    await deleteValue(DbKeys.otpBlockEndTime);
    await deleteValue(DbKeys.otpRetryLevel);
  }

  /// Save assigned unit IDs for operator scope filtering
  /// Units are stored as a comma-separated string
  Future<void> setAssignedUnitIds(List<int> unitIds) async {
    final idsString = unitIds.join(',');
    await setValue(DbKeys.assignedUnitIds, idsString);
  }

  /// Save assigned region IDs for employee scope filtering
  Future<void> setAssignedRegionIds(List<int> regionIds) async {
    final idsString = regionIds.join(',');
    await setValue(DbKeys.assignedRegionIds, idsString);
  }

  /// Retrieve assigned unit IDs for operator scope filtering
  Future<List<int>> getAssignedUnitIds() async {
    final value = await getValue(DbKeys.assignedUnitIds);
    if (value == null || value.isEmpty) return [];

    return value
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .where((e) => e != null)
        .cast<int>()
        .toList();
  }

  /// Retrieve assigned region IDs for employee scope filtering
  Future<List<int>> getAssignedRegionIds() async {
    final value = await getValue(DbKeys.assignedRegionIds);
    if (value == null || value.isEmpty) return [];

    return value
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .where((e) => e != null)
        .cast<int>()
        .toList();
  }

  /// Check if a specific unit ID is in the operator's assigned units
  Future<bool> isAssignedUnit(int unitId) async {
    final assignedIds = await getAssignedUnitIds();
    return assignedIds.contains(unitId);
  }
}

import 'package:qatrah/core/auth/session_notifier.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/network/api_client.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/network/interceptors/auth_interceptor.dart';
import 'package:qatrah/core/utils/jwt_decoder.dart';

enum AuthSessionStatus {
  authenticated,
  unauthenticated,
  expired,
}

class AuthSessionResult {
  const AuthSessionResult({
    required this.status,
    this.isEmployee = false,
  });

  final AuthSessionStatus status;
  final bool isEmployee;

  bool get isAuthenticated => status == AuthSessionStatus.authenticated;
  bool get isExpired => status == AuthSessionStatus.expired;
}

class AuthSessionService {
  AuthSessionService({
    required SecureStorage secureStorage,
    required ApiClient apiClient,
    required ApiService apiService,
    SessionNotifier? sessionNotifier,
  }) : _secureStorage = secureStorage,
       _apiClient = apiClient,
       _apiService = apiService,
       _sessionNotifier = sessionNotifier;

  static const pendingLogoutReasonKey = 'pending_logout_reason';
  static const sessionExpiredReason = 'session_expired';
  static const _clockSkew = Duration(seconds: 15);

  final SecureStorage _secureStorage;
  final ApiClient _apiClient;
  final ApiService _apiService;
  final SessionNotifier? _sessionNotifier;

  Future<AuthSessionResult> ensureValidSession() async {
    final token = await _secureStorage.getToken();
    final logged = await _secureStorage.getLoggedInStatus();
    final role = await _secureStorage.getRole();

    if (token == null || token.isEmpty || !(logged ?? false)) {
      await clearSession();
      return const AuthSessionResult(status: AuthSessionStatus.unauthenticated);
    }

    if (!_isTokenExpired(token)) {
      return AuthSessionResult(
        status: AuthSessionStatus.authenticated,
        isEmployee: _isEmployeeRole(role, token),
      );
    }

    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      // Only mark as expired if we were supposedly logged in
      await clearSession(markSessionExpired: logged ?? false);
      return const AuthSessionResult(status: AuthSessionStatus.expired);
    }

    // Deliberately do NOT hard-log-out on a client-side decode of the refresh
    // token: device clock skew (or a non-standard `exp`) would falsely classify
    // a still-valid token as expired and sign the user out for no reason — an
    // intermittent, untraceable logout. The server is the single source of
    // truth: attempt the refresh and only clear if it actually rejects us.
    final refreshOutcome = await _apiClient.authInterceptor.refreshSession();

    if (refreshOutcome == RefreshSessionOutcome.networkError) {
      // Network unavailable — credentials are intact, redirect to login without wiping
      return const AuthSessionResult(status: AuthSessionStatus.unauthenticated);
    }

    if (refreshOutcome != RefreshSessionOutcome.success) {
      await clearSession(markSessionExpired: logged ?? false);
      return const AuthSessionResult(status: AuthSessionStatus.expired);
    }

    final refreshedToken = await _secureStorage.getToken();
    final refreshedRole = await _secureStorage.getRole();
    // The refresh just succeeded, so trust it: only require that a token was
    // actually persisted. Re-decoding it here with a skewed clock could
    // falsely flag the brand-new token as expired and log the user straight
    // back out. If the token really is bad, the next request's 401 routes
    // through the interceptor's (now single-flighted) refresh path.
    if (refreshedToken == null || refreshedToken.isEmpty) {
      await clearSession(markSessionExpired: true);
      return const AuthSessionResult(status: AuthSessionStatus.expired);
    }

    return AuthSessionResult(
      status: AuthSessionStatus.authenticated,
      isEmployee: _isEmployeeRole(refreshedRole, refreshedToken),
    );
  }

  Future<void> clearSession({bool markSessionExpired = false}) async {
    if (markSessionExpired) {
      await _secureStorage.setDynamicValue(
        pendingLogoutReasonKey,
        sessionExpiredReason,
      );
    }
    _apiService.clearAuthHeader();
    await _secureStorage.clearAuth();

    // Only the "expired" path needs to actively wake the router. The other
    // clears here (missing token / network) are already driven *by* the
    // redirect guard, which consumes the returned status directly, so emitting
    // would be redundant. Emitted strictly after the storage wipe above to
    // honour SessionNotifier's ordering contract.
    if (markSessionExpired) {
      _sessionNotifier?.notifySessionEnded(SessionEndReason.expired);
    }
  }

  Future<bool> consumeSessionExpiredFlag() async {
    final reason = await _secureStorage.getDynamicValue(pendingLogoutReasonKey);
    if (reason != sessionExpiredReason) {
      return false;
    }

    await _secureStorage.deleteDynamicValue(pendingLogoutReasonKey);
    return true;
  }

  bool _isTokenExpired(String token) {
    try {
      final decoded = JwtDecoder.decode(token);
      final exp = decoded['exp'];
      if (exp is! num) {
        return true;
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );
      return DateTime.now().toUtc().add(_clockSkew).isAfter(expiry);
    } catch (_) {
      return true;
    }
  }

  bool _isEmployeeRole(String? role, String token) {
    if (role == 'OPERATOR' || role == 'ADMIN' || role == 'EMPLOYEE') {
      return true;
    }

    try {
      final decoded = JwtDecoder.decode(token);
      final realmAccess = decoded['realm_access'];
      if (realmAccess is Map && realmAccess['roles'] is List) {
        final roles = List<String>.from(realmAccess['roles'] as List);
        return roles.contains('OPERATOR') || roles.contains('ADMIN');
      }
    } catch (_) {
      return false;
    }

    return false;
  }
}

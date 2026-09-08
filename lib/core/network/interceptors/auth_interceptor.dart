import 'package:dio/dio.dart';
import 'package:qatrah/core/auth/app_lock_state.dart';
import 'package:qatrah/core/auth/auth_session_service.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/auth/session_notifier.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/network/api_client.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/network/network_alert_service.dart';
import 'package:qatrah/core/utils/app_logger.dart';

enum RefreshSessionOutcome { success, authExpired, networkError }

class _RefreshOutcomeResult {
  const _RefreshOutcomeResult(this.outcome, {this.token});
  final String? token;
  final RefreshSessionOutcome outcome;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage secureStorage,
    required ApiClient apiClient,
    AppLockState? lockState,
    SecureAuthStorage? authStorage,
    String refreshPath = ApiEndpoints.refresh,
    NetworkAlertService? networkAlertService,
    SessionNotifier? sessionNotifier,
  }) : _secureStorage = secureStorage,
       _apiClient = apiClient,
       _lockState = lockState,
       _authStorage = authStorage,
       _refreshPath = refreshPath,
       _networkAlertService = networkAlertService,
       _sessionNotifier = sessionNotifier;

  final SecureStorage _secureStorage;
  final ApiClient _apiClient;
  final AppLockState? _lockState;
  final SecureAuthStorage? _authStorage;
  final String _refreshPath;
  final NetworkAlertService? _networkAlertService;
  final SessionNotifier? _sessionNotifier;

  ApiService? _apiService;
  String? _cachedToken;
  String? _cachedRefreshToken;

  Dio get _dio => _apiClient.dio;

  // Single-flight slot. While a refresh is running, every other caller — a
  // concurrent 401 in [onError] OR ensureValidSession via [refreshSession] —
  // awaits this *same* future instead of starting its own. This is the fix for
  // Keycloak refresh-token rotation: two parallel refreshes would each spend
  // the same refresh token, and the loser receives a 401 on an already-rotated
  // token, wrongly tearing down a perfectly good session.
  Future<_RefreshOutcomeResult>? _inFlightRefresh;

  Future<void> _clearAuthSession({bool markSessionExpired = false}) async {
    if (markSessionExpired) {
      await _secureStorage.setDynamicValue(
        AuthSessionService.pendingLogoutReasonKey,
        AuthSessionService.sessionExpiredReason,
      );
    }
    _apiService?.clearAuthHeader();
    await _secureStorage.clearAuth();
    clearCachedToken();

    // Storage is now fully wiped (awaited above) and the in-memory token cache
    // is cleared — only NOW is it safe to wake the router. Emitting any earlier
    // would let the redirect guard read a stale token and bounce the user back
    // into the app (the "login loop"). This is the wake-up that fixes a 401
    // arriving while the user is sitting on a protected screen with no
    // navigation event to otherwise re-trigger the guard.
    _sessionNotifier?.notifySessionEnded(SessionEndReason.expired);
  }

  Future<RefreshSessionOutcome> refreshSession() async {
    final result = await _refreshTokenSingleFlight();
    return result.outcome;
  }

  /// Coalesces concurrent refresh attempts into a single in-flight network
  /// call. The first caller starts the refresh; everyone who arrives while it
  /// runs awaits the same future and shares its result. See [_inFlightRefresh].
  Future<_RefreshOutcomeResult> _refreshTokenSingleFlight() {
    final existing = _inFlightRefresh;
    if (existing != null) return existing;

    final future = _performRefresh();
    _inFlightRefresh = future;
    // Release the slot once finished so the *next* expiry runs a fresh refresh
    // using the token this round just rotated in.
    future.whenComplete(() {
      if (identical(_inFlightRefresh, future)) _inFlightRefresh = null;
    });
    return future;
  }

  /// Reads the latest stored refresh token and performs the network refresh.
  /// Kept separate from [_refreshTokenSingleFlight] so the token is read fresh
  /// at the moment the single flight actually starts.
  Future<_RefreshOutcomeResult> _performRefresh() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return const _RefreshOutcomeResult(RefreshSessionOutcome.authExpired);
    }
    return _refreshAccessToken(refreshToken);
  }

  void setApiService(ApiService apiService) {
    _apiService = apiService;
  }

  String _sanitizeToken(String token) {
    return token.trim().replaceAll('\n', '').replaceAll('\r', '');
  }

  bool _containsNonLatin1(String value) {
    return value.runes.any((codePoint) => codePoint > 255);
  }

  String _maskToken(String? value) {
    if (value == null || value.isEmpty) return '<empty>';
    if (value.length <= 12) return value;
    return '${value.substring(0, 8)}...${value.substring(value.length - 4)}';
  }

  Future<void> setCachedToken(String token) async {
    _cachedToken = _sanitizeToken(token);
    final storedToken = await _secureStorage.getToken();
    if (storedToken != _cachedToken) {
      AppLogger.debug(
        '[AUTH INTERCEPTOR] token mismatch detected, forcing cache update',
      );
      _cachedToken = storedToken != null
          ? _sanitizeToken(storedToken)
          : _cachedToken;
    }
  }

  void clearCachedToken() {
    _cachedToken = null;
    _cachedRefreshToken = null;
  }

  Future<void> forceCacheRefresh() async {
    _cachedToken = null;
    _cachedRefreshToken = null;
    await _getToken();
    await _getRefreshToken();
  }

  Future<String?> _getToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }
    final token = await _secureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      _cachedToken = _sanitizeToken(token);
    }
    return _cachedToken;
  }

  Future<String?> _getRefreshToken() async {
    if (_cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty) {
      return _cachedRefreshToken;
    }
    final token = await _secureStorage.getRefreshToken();
    if (token != null && token.isNotEmpty) {
      _cachedRefreshToken = token;
    }
    return _cachedRefreshToken;
  }

  bool _isAuthEndpoint(String path) {
    final authPaths = <String>[
      ApiEndpoints.citizenLogin,
      ApiEndpoints.citizenRefresh,
      ApiEndpoints.citizenLogout,
      ApiEndpoints.employeeLogin,
      ApiEndpoints.employeeLogout,
      ApiEndpoints.forgetPassword,
      ApiEndpoints.refresh,
      ApiEndpoints.register,
      ApiEndpoints.sendOtp,
      ApiEndpoints.verifyOtp,
      ApiEndpoints.keycloakLogoutUrl,
    ];

    return authPaths.any((p) => path.contains(p));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Block protected requests while a lockable session is locked.
      // Auth endpoints (login/refresh/logout/OTP) bypass this gate so the
      // unlock flow itself can complete.
      if (!_isAuthEndpoint(options.path) &&
          _lockState != null &&
          _authStorage != null &&
          _lockState.isLocked) {
        final isLockable = await _authStorage.isAppLockSession();
        final pinSet = await _authStorage.isPinSet();
        if (isLockable && pinSet) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'app_locked',
            ),
          );
          return;
        }
      }

      if (!_isAuthEndpoint(options.path)) {
        final token = await _getToken();

        AppLogger.debug(
          '[AUTH INTERCEPTOR] request=${options.path} | '
          'token=${token != null && token.isNotEmpty ? 'Present' : 'Missing'}',
        );

        if (token != null && token.isNotEmpty) {
          final sanitizedToken = _sanitizeToken(token);
          final authHeader = 'Bearer $sanitizedToken';
          options.headers['Authorization'] = authHeader;

          AppLogger.debug(
            '[AUTH INTERCEPTOR] header details | '
            'tokenLength=${token.length} | '
            'sanitizedLength=${sanitizedToken.length} | '
            'hasNewLine=${token.contains('\n') || token.contains('\r')} | '
            'hasNonLatin1=${_containsNonLatin1(authHeader)} | '
            'preview=${_maskToken(sanitizedToken)}',
          );
        } else {
          options.headers.remove('Authorization');
        }
      } else {
        options.headers.remove('Authorization');
      }

      if (options.path.contains('/notifications/device-token')) {
        final authHeader = options.headers['Authorization']?.toString();
        AppLogger.debug(
          '[FCM REQUEST] path=${options.path} | headers=${options.headers}',
        );
        AppLogger.debug(
          '[FCM REQUEST] Authorization analysis | '
          'exists=${authHeader != null} | '
          'hasNonLatin1=${authHeader != null && _containsNonLatin1(authHeader)} | '
          'preview=${_maskToken(authHeader?.replaceFirst('Bearer ', ''))}',
        );
      }

      handler.next(options);
    } catch (e) {
      AppLogger.error('[AUTH INTERCEPTOR] Error in onRequest: $e');
      handler.next(options);
    }
  }

  /// Marks a request that was already retried once with a freshly-refreshed
  /// token. A *second* 401 on such a request means the token is valid but the
  /// backend is rejecting on authorization — never an expired session.
  static const _retriedAfterRefreshKey = '__qatrah_retried_after_refresh';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    final statusCode = err.response?.statusCode;

    // Login failures are surfaced to the caller as-is.
    if (path.contains(ApiEndpoints.employeeLogin) ||
        path.contains(ApiEndpoints.citizenLogin)) {
      return handler.next(err);
    }

    // 403 Forbidden = the user IS authenticated but lacks permission for this
    // action/resource. This is an AUTHORIZATION outcome, never a session
    // problem: we must NOT refresh and NOT log the user out. The caller shows
    // a friendly "no permission" message and the user stays exactly where they
    // are. This is the root fix for employees being kicked out on a
    // role/permission mismatch.
    if (statusCode == 403) {
      return handler.next(err);
    }

    // Network/connectivity errors (no response) — session is intact.
    if (err.response == null &&
        (err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.unknown)) {
      return handler.next(err);
    }

    // 5xx server errors — preserve session, let the caller handle/retry.
    if (statusCode != null && statusCode >= 500) {
      return handler.next(err);
    }

    // Any non-401 response (400/404/409 …) is a normal request error. It is
    // surfaced to the caller and NEVER ends the session. In particular a 404
    // no longer logs anyone out.
    if (statusCode != 401) {
      return handler.next(err);
    }

    // ---- 401 Unauthorized: token-level problem. Try ONE silent refresh. ----

    // The refresh call itself returned 401 → the session is genuinely dead.
    if (path.contains(_refreshPath) ||
        path.contains(ApiEndpoints.citizenRefresh) ||
        path.contains(ApiEndpoints.refresh)) {
      AppLogger.error(
        '[AUTH INTERCEPTOR] Refresh request 401 — clearing session',
      );
      await _clearAuthSession(markSessionExpired: true);
      return handler.next(err);
    }

    // Already retried once with a fresh token and still 401 → the token is
    // valid, so this is an authorization rejection (backend returning 401
    // where it should return 403). Surface it WITHOUT logging out.
    if (err.requestOptions.extra[_retriedAfterRefreshKey] == true) {
      AppLogger.error(
        '[AUTH INTERCEPTOR] 401 after refresh — treating as authorization, '
        'session preserved',
      );
      return handler.next(err);
    }

    final refreshToken = await _getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      AppLogger.error('[AUTH INTERCEPTOR] No refresh token — clearing session');
      await _clearAuthSession(markSessionExpired: true);
      return handler.next(err);
    }

    try {
      // Funnel through the shared single flight. Concurrent 401s — and any
      // ensureValidSession refresh racing from the router/splash — all await
      // this one refresh, so the rotating Keycloak refresh token is spent
      // exactly once. Each caller then retries its OWN original request with
      // the shared new token.
      AppLogger.debug('[AUTH INTERCEPTOR] Attempting to refresh token...');
      final result = await _refreshTokenSingleFlight();

      if (result.outcome == RefreshSessionOutcome.networkError) {
        AppLogger.error(
          '[AUTH INTERCEPTOR] Network error during refresh, session preserved',
        );
        return handler.next(err);
      }

      if (result.token == null) {
        AppLogger.error('[AUTH INTERCEPTOR] Auth expired, clearing session');
        await _clearAuthSession(markSessionExpired: true);
        return handler.next(err);
      }

      AppLogger.debug('[AUTH INTERCEPTOR] Token refreshed successfully');
      final retry = await _retryRequest(err.requestOptions, result.token!);
      return handler.resolve(retry);
    } catch (e) {
      AppLogger.error(
        '[AUTH INTERCEPTOR] Unexpected error during token refresh: $e',
      );
      clearCachedToken();
      return handler.next(err);
    }
  }

  Future<_RefreshOutcomeResult> _refreshAccessToken(String refreshToken) async {
    final refreshDio = Dio(_dio.options)
      ..httpClientAdapter = _dio.httpClientAdapter;

    try {
      final role = await _secureStorage.getRole();
      final refreshPath = role == 'CITIZEN'
          ? ApiEndpoints.citizenRefresh
          : _refreshPath;
      final response = await refreshDio.post<Map<String, dynamic>>(
        refreshPath,
        data: {
          'refreshToken': refreshToken,
          'refresh_token': refreshToken,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode != 200 || response.data is! Map) {
        AppLogger.error(
          '[AUTH INTERCEPTOR] Refresh response invalid: ${response.statusCode}',
        );
        return const _RefreshOutcomeResult(RefreshSessionOutcome.authExpired);
      }

      final data = response.data!;
      final accessToken =
          (data['accessToken'] as String?) ??
          (data['access_token'] as String?) ??
          (data['token'] as String?);

      final newRefreshToken =
          (data['refreshToken'] as String?) ??
          (data['refresh_token'] as String?);

      if (accessToken == null || accessToken.isEmpty) {
        AppLogger.error(
          '[AUTH INTERCEPTOR] No access token in refresh response',
        );
        return const _RefreshOutcomeResult(RefreshSessionOutcome.authExpired);
      }

      AppLogger.debug('[AUTH INTERCEPTOR] Saving new access token');
      final storedRole = await _secureStorage.getRole();
      await _secureStorage.setToken(accessToken, role: storedRole);
      if (_apiService != null) {
        await _apiService!.updateAuthHeader(accessToken);
      }
      await forceCacheRefresh();

      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        AppLogger.debug('[AUTH INTERCEPTOR] Saving new refresh token');
        await _secureStorage.setRefreshToken(newRefreshToken);
        _cachedRefreshToken = newRefreshToken;
      }

      return _RefreshOutcomeResult(
        RefreshSessionOutcome.success,
        token: accessToken,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      AppLogger.error(
        '[AUTH INTERCEPTOR] Refresh DioException: status=$status error=${e.message}',
      );
      if (status != null && (status == 400 || status == 401 || status == 403)) {
        return const _RefreshOutcomeResult(RefreshSessionOutcome.authExpired);
      }
      return const _RefreshOutcomeResult(RefreshSessionOutcome.networkError);
    } catch (e) {
      AppLogger.error('[AUTH INTERCEPTOR] Refresh unexpected error: $e');
      return const _RefreshOutcomeResult(RefreshSessionOutcome.networkError);
    }
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String accessToken,
  ) {
    final sanitizedToken = _sanitizeToken(accessToken);
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer $sanitizedToken',
        },
        extra: {
          ...requestOptions.extra,
          _retriedAfterRefreshKey: true,
        },
      ),
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
    );
  }
}

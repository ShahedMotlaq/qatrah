// lib/features/auth/data/data_sources/auth_remote_data_source.dart

import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/utils/app_logger.dart';
import 'package:qatrah/core/utils/input_sanitizer.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._apiService);

  final ApiService _apiService;

  Future<void> updateAuthHeader(String token) =>
      _apiService.updateAuthHeader(token);

  void clearAuthHeader() => _apiService.clearAuthHeader();

  /// Send OTP
  Future<Map<String, dynamic>> sendOtp(
    String phoneNumber, {
    required bool rememberMe,
    required String role,
  }) async {
    return _apiService.post(
      endPoint: ApiEndpoints.sendOtp,
      data: {
        'phoneNumber': InputSanitizer.sanitizeInput(phoneNumber),
        'rememberMe': rememberMe,
        'role': role,
      },
    );
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    return _apiService.post(
      endPoint: ApiEndpoints.verifyOtp,
      data: {
        'phoneNumber': InputSanitizer.sanitizeInput(phoneNumber),
        'otpCode': InputSanitizer.sanitizeInput(otpCode),
      },
    );
  }

  /// Employee login
  Future<Map<String, dynamic>> employeeLogin({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    return _apiService.post(
      endPoint: ApiEndpoints.employeeLogin,
      data: {
        'username': InputSanitizer.sanitizeInput(username),
        'password': InputSanitizer.sanitizeInput(password),
      },
    );
  }

  /// Citizen login
  Future<Map<String, dynamic>> citizenLogin({
    required String username,
    required String password,
  }) async {
    return _apiService.post(
      endPoint: ApiEndpoints.citizenLogin,
      data: {
        'username': InputSanitizer.sanitizeInput(username),
        'password': InputSanitizer.sanitizeInput(password),
      },
    );
  }

  Future<Map<String, dynamic>> citizenRegister({
    required String username,
    required String fullName,
    required String password,
  }) async {
    return _apiService.post(
      endPoint: ApiEndpoints.register,
      data: {
        'username': InputSanitizer.sanitizeInput(username),
        'fullName': InputSanitizer.sanitizeInput(fullName),
        'password': InputSanitizer.sanitizeInput(password),
      },
    );
  }

  Future<Map<String, dynamic>> logout({
    required String endPoint,
    required String refreshToken,
  }) async {
    return _apiService.post(
      endPoint: endPoint,
      data: {'refreshToken': refreshToken},
    );
  }

  /// Fetch current user profile (all roles).
  Future<Map<String, dynamic>> getCurrentUser() async {
    return _apiService.get(endPoint: ApiEndpoints.currentUser);
  }

  /// Update FCM token for push notifications
  Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async {
    AppLogger.debug(
      '[FCM REMOTE] updateFcmToken | '
      'tokenLength=${fcmToken.length} | '
      'hasNewLine=${fcmToken.contains('\n') || fcmToken.contains('\r')} | '
      'preview=${fcmToken.length > 20 ? '${fcmToken.substring(0, 12)}...${fcmToken.substring(fcmToken.length - 6)}' : fcmToken}',
    );
    return _apiService.post(
      endPoint: ApiEndpoints.notificationsDeviceToken,
      data: {'token': fcmToken},
    );
  }

  /// Remove FCM token for push notifications
  Future<Map<String, dynamic>> removeFcmToken() async {
    return _apiService.delete(
      endPoint: ApiEndpoints.notificationsDeviceToken,
    );
  }
}

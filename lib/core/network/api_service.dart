import 'dart:io';
import 'package:dio/dio.dart';
import 'package:qatrah/core/errors/app_error_messages.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/network/api_client.dart';
import 'package:qatrah/core/network/interceptors/auth_interceptor.dart';
import 'package:qatrah/core/utils/app_logger.dart';

class ApiService {
  ApiService(this._apiClient);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  String _sanitizeHeaderValue(String value) {
    return value.trim().replaceAll('\n', '').replaceAll('\r', '');
  }

  String _maskToken(String? value) {
    if (value == null || value.isEmpty) return '<empty>';
    if (value.length <= 12) return value;
    return '${value.substring(0, 8)}...${value.substring(value.length - 4)}';
  }

  bool _containsNonLatin1(String value) {
    return value.runes.any((codePoint) => codePoint > 255);
  }

  /// Update Authorization header in Dio global options and refresh token cache.
  Future<void> updateAuthHeader(String token) async {
    final sanitizedToken = _sanitizeHeaderValue(token);
    final authHeader = 'Bearer $sanitizedToken';
    _dio.options.headers['Authorization'] = authHeader;
    AppLogger.debug(
      '[AUTH HEADER] updateAuthHeader | '
      'tokenLength=${token.length} | '
      'sanitizedLength=${sanitizedToken.length} | '
      'hasNewLine=${token.contains('\n') || token.contains('\r')} | '
      'hasNonLatin1=${_containsNonLatin1(authHeader)} | '
      'preview=${_maskToken(sanitizedToken)}',
    );
    // Update the interceptor's in-memory cache to prevent 401s
    // caused by flutter_secure_storage write/read race conditions.
    try {
      for (final interceptor in _dio.interceptors) {
        if (interceptor is AuthInterceptor) {
          await interceptor.setCachedToken(sanitizedToken);
          break;
        }
      }
    } catch (e) {
      AppLogger.error('⚠️ Failed to update interceptor cache: $e');
    }
  }

  /// Clear Authorization header from Dio global options and clear token cache.
  void clearAuthHeader() {
    _dio.options.headers.remove('Authorization');
    try {
      for (final interceptor in _dio.interceptors) {
        if (interceptor is AuthInterceptor) {
          interceptor.clearCachedToken();
          break;
        }
      }
    } catch (e) {
      AppLogger.error('⚠️ Failed to clear interceptor cache: $e');
    }
  }

  /// GET request
  Future<Map<String, dynamic>> get({
    required String endPoint,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _performRequest(
      () => _dio.get(
        endPoint,
        queryParameters: queryParameters,
      ),
    );
  }

  /// POST request
  Future<Map<String, dynamic>> post({
    required String endPoint,
    dynamic data,
  }) async {
    if (endPoint.contains('/notifications/device-token')) {
      final authHeader = _dio.options.headers['Authorization']?.toString();
      AppLogger.debug('[FCM API] POST $endPoint | body=$data');
      AppLogger.debug(
        '[FCM API] global Authorization | exists=${authHeader != null} | '
        'hasNonLatin1=${authHeader != null && _containsNonLatin1(authHeader)} | '
        'preview=${_maskToken(authHeader?.replaceFirst('Bearer ', ''))}',
      );
    }
    return _performRequest(() => _dio.post(endPoint, data: data));
  }

  /// PUT request
  Future<Map<String, dynamic>> put({
    required String endPoint,
    dynamic data,
  }) async {
    return _performRequest(() => _dio.put(endPoint, data: data));
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch({
    required String endPoint,
    dynamic data,
  }) async {
    return _performRequest(() => _dio.patch(endPoint, data: data));
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete({
    required String endPoint,
    String? id,
  }) async {
    final path = id == null || id.isEmpty ? endPoint : '$endPoint/$id';
    return _performRequest(() => _dio.delete(path));
  }

  /// Download file
  Future<File> downloadFile({
    required String endPoint,
    required String filePath,
    void Function(int, int)? onProgress,
  }) async {
    try {
      await _dio.download(
        endPoint,
        filePath,
        onReceiveProgress: onProgress,
      );
      return File(filePath);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (_) {
      throw ServerFailure(AppErrorMessages.unknown(), errorCode: 'U1');
    }
  }

  /// perform request
  Future<Map<String, dynamic>> _performRequest(
    Future<Response> Function() request,
  ) async {
    try {
      final response = await request();
      return _handleResponse(response);
    } on DioException catch (e) {
      AppLogger.error(
        '[API ERROR] DioException | type=${e.type} | '
        'status=${e.response?.statusCode} | path=${e.requestOptions.path} | '
        'message=${e.message} | error=${e.error}',
      );
      throw _handleError(e);
    } catch (e) {
      AppLogger.error('[API ERROR] Non-Dio exception: $e');
      throw ServerFailure(AppErrorMessages.fromException(e), errorCode: 'U1');
    }
  }

  /// handle response
  Map<String, dynamic> _handleResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {'data': response.data};
  }

  /// hande error
  Failure _handleError(DioException error) {
    final errObj = error.error;
    if (errObj is Failure) return errObj;
    return ServerFailure.fromDioError(error);
  }
}

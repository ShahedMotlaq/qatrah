import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:qatrah/core/auth/app_lock_state.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/auth/session_notifier.dart';
import 'package:qatrah/core/config/env.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/network/interceptors/auth_interceptor.dart';
import 'package:qatrah/core/network/interceptors/dio_interceptors.dart';
import 'package:qatrah/core/network/interceptors/logging_interceptor.dart';
import 'package:qatrah/core/network/network_alert_service.dart';

class ApiClient {
  factory ApiClient({
    required SecureStorage secureStorage,
    AppLockState? lockState,
    SecureAuthStorage? authStorage,
    NetworkAlertService? networkAlertService,
    SessionNotifier? sessionNotifier,
  }) {
    return _instance ??= ApiClient._internal(
      secureStorage: secureStorage,
      lockState: lockState,
      authStorage: authStorage,
      networkAlertService: networkAlertService,
      sessionNotifier: sessionNotifier,
    );
  }

  ApiClient._internal({
    required SecureStorage secureStorage,
    AppLockState? lockState,
    SecureAuthStorage? authStorage,
    NetworkAlertService? networkAlertService,
    SessionNotifier? sessionNotifier,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: Env.baseUrl,
           connectTimeout: const Duration(seconds: 20),
           receiveTimeout: const Duration(seconds: 20),
           sendTimeout: const Duration(seconds: 20),
           headers: const {
             'Accept': 'application/json',
             'Content-Type': 'application/json',
           },
         ),
       ) {
    authInterceptor = AuthInterceptor(
      secureStorage: secureStorage,
      apiClient: this,
      lockState: lockState,
      authStorage: authStorage,
      networkAlertService: networkAlertService,
      sessionNotifier: sessionNotifier,
    );

    dio.interceptors.addAll([
      authInterceptor,
      ErrorFailureInterceptor(),
      if (kDebugMode) LoggingInterceptor.i,
    ]);
  }
  static ApiClient? _instance;

  final Dio dio;
  late final AuthInterceptor authInterceptor;

  /// Set the ApiService reference on the AuthInterceptor after ApiService is created.
  /// This avoids circular dependency between ApiClient and ApiService.
  void setApiServiceForInterceptor(ApiService apiService) {
    authInterceptor.setApiService(apiService);
  }
}

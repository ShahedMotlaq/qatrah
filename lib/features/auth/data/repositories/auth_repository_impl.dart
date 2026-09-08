import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:qatrah/core/errors/app_error_messages.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/storage_service.dart';
import 'package:qatrah/core/utils/app_logger.dart';
import 'package:qatrah/core/utils/phone_number_formatter.dart';
import 'package:qatrah/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:qatrah/features/auth/data/models/user_model.dart';
import 'package:qatrah/features/auth/domain/entities/user_entity.dart';
import 'package:qatrah/features/auth/domain/repositories/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorage _secureStorage = getIt<SecureStorage>();
  final StorageService _storageService = getIt<StorageService>();

  @override
  Future<Either<Failure, void>> sendOtp(
    String phoneNumber, {
    bool rememberMe = true,
    String role = 'CITIZEN',
  }) async {
    try {
      final formattedPhone = PhoneNumberFormatter.format(phoneNumber);
      final response = await _remoteDataSource.sendOtp(
        formattedPhone,
        rememberMe: rememberMe,
        role: role,
      );
      AppLogger.debug('Send OTP Response: $response');

      final success = response['success'];
      final status = response['status'];
      final hasExplicitFailure =
          success == false ||
          status == false ||
          response['error'] != null ||
          response['errors'] != null;

      if (!hasExplicitFailure) {
        return const Right(null);
      }
      return Left(
        ServerFailure(response['message']?.toString() ?? 'error_send_otp'),
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp(
    String phoneNumber,
    String otpCode,
  ) async {
    try {
      final formattedPhone = PhoneNumberFormatter.format(phoneNumber);
      final response = await _remoteDataSource.verifyOtp(
        phoneNumber: formattedPhone,
        otpCode: otpCode,
      );
      AppLogger.debug('Verify OTP Response: $response');

      final isSuccess = response['success'] == true;
      final token = response['token'] ?? response['access_token'];
      final refreshToken =
          response['refresh_token'] ?? response['refreshToken'];

      if (isSuccess && token != null) {
        final tokenStr = token.toString();
        final refreshTokenStr = refreshToken?.toString();

        final user = UserModelMapper.fromJson({
          ...response,
          'refreshToken': refreshToken,
        });

        // Unified session save per save_login.md spec
        await _storageService.saveLoginSession(
          token: tokenStr,
          userType: user.role,
          userData: user.toJson(),
          refreshToken: refreshTokenStr,
          expiresIn: response['expires_in'] as int?,
        );

        await _remoteDataSource.updateAuthHeader(tokenStr);

        try {
          final profileResponse = await _remoteDataSource.getCurrentUser();
          final profileUser = UserModelMapper.fromJson({
            ...profileResponse,
            'token': tokenStr,
            'refreshToken': refreshToken,
          });
          return Right(profileUser);
        } catch (e) {
          AppLogger.error(
            'Failed to fetch user profile after OTP verification: $e',
          );
          return Right(user);
        }
      }
      return Left(
        ServerFailure(response['message']?.toString() ?? 'error_verify_otp'),
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> citizenLogin(
    String username,
    String password,
  ) async {
    try {
      final response = await _remoteDataSource.citizenLogin(
        username: username.trim(),
        password: password.trim(),
      );
      AppLogger.debug('Citizen Login Response: $response');

      final accessToken = response['access_token'] ?? response['token'];
      final refreshToken =
          response['refresh_token'] ?? response['refreshToken'];

      if (accessToken != null && accessToken.toString().isNotEmpty) {
        final tokenStr = accessToken.toString();
        final user = UserModelMapper.fromJson({
          ...response,
          'token': tokenStr,
          'refreshToken': refreshToken,
          'role': response['role'] ?? 'CITIZEN',
        });

        await _storageService.saveLoginSession(
          token: tokenStr,
          userType: user.role,
          userData: user.toJson(),
          refreshToken: refreshToken?.toString(),
          expiresIn: response['expires_in'] as int?,
        );

        await _remoteDataSource.updateAuthHeader(tokenStr);
        return Right(user);
      }
      return Left(
        ServerFailure(response['message']?.toString() ?? 'error_login'),
      );
    } catch (e) {
      return _handleLoginError(e);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> citizenRegister({
    required String username,
    required String fullName,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.citizenRegister(
        username: username.trim(),
        fullName: fullName.trim(),
        password: password.trim(),
      );
      AppLogger.debug('Citizen Register Response: $response');

      final accessToken = response['access_token'] ?? response['token'];
      final refreshToken =
          response['refresh_token'] ?? response['refreshToken'];

      if (accessToken != null && accessToken.toString().isNotEmpty) {
        final tokenStr = accessToken.toString();
        final user = UserModelMapper.fromJson({
          ...response,
          'token': tokenStr,
          'refreshToken': refreshToken,
          'role': response['role'] ?? 'CITIZEN',
        });

        await _storageService.saveLoginSession(
          token: tokenStr,
          userType: user.role,
          userData: user.toJson(),
          refreshToken: refreshToken?.toString(),
          expiresIn: response['expires_in'] as int?,
        );

        await _remoteDataSource.updateAuthHeader(tokenStr);
        return Right(user);
      }
      return Left(
        ServerFailure(response['message']?.toString() ?? 'error_register'),
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> employeeLogin(
    String username,
    String password, {
    required bool rememberMe,
  }) async {
    try {
      final response = await _remoteDataSource.employeeLogin(
        username: username.trim(),
        password: password.trim(),
        rememberMe: rememberMe,
      );
      AppLogger.debug('Employee Login Response: $response');

      final accessToken = response['access_token'] ?? response['token'];
      final refreshToken =
          response['refresh_token'] ?? response['refreshToken'];

      if (accessToken != null && accessToken.toString().isNotEmpty) {
        final tokenStr = accessToken.toString();
        final user = UserModelMapper.fromJson({
          ...response,
          'token': tokenStr,
          'refreshToken': refreshToken,
          'username': response['username'] ?? username.trim(),
          'role': response['role'] ?? 'OPERATOR',
        });

        await _storageService.saveLoginSession(
          token: tokenStr,
          userType: user.role,
          userData: user.toJson(),
          refreshToken: refreshToken?.toString(),
          expiresIn: response['expires_in'] as int?,
          keycloakRoles: user.role == 'ADMIN' || user.role == 'OPERATOR'
              ? [user.role]
              : null,
        );

        await _remoteDataSource.updateAuthHeader(tokenStr);
        await _secureStorage.setAssignedUnitIds(user.assignedUnits);
        await _secureStorage.setAssignedRegionIds(user.assignedRegionIds);
        return Right(user);
      }
      return Left(
        ServerFailure(response['message']?.toString() ?? 'error_login'),
      );
    } catch (e) {
      return _handleLoginError(e);
    }
  }

  @override
  Future<Either<Failure, void>> logout({required String redirectUri}) async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final role = await _secureStorage.getRole();
        await _remoteDataSource.logout(
          endPoint: role == 'CITIZEN'
              ? ApiEndpoints.citizenLogout
              : ApiEndpoints.employeeLogout,
          refreshToken: refreshToken,
        );
      }

      _remoteDataSource.clearAuthHeader();
      await _storageService.logout();
      return const Right(null);
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final storedRole = await _secureStorage.getRole();
      final isEmployee =
          storedRole == 'OPERATOR' ||
          storedRole == 'ADMIN' ||
          storedRole == 'EMPLOYEE';
      final response = await _remoteDataSource.getCurrentUser(
        isEmployee: isEmployee,
      );
      AppLogger.debug('GetCurrentUser Response: $response');

      final responseRole = response['role']?.toString();
      final effectiveRole = (responseRole != null && responseRole.isNotEmpty)
          ? responseRole
          : (storedRole ?? 'CITIZEN');
      final user = UserModelMapper.fromJson({
        ...response,
        'role': effectiveRole,
      });
      await _secureStorage.setUserName(user.username);
      await _secureStorage.setRole(user.role);
      await _secureStorage.setAssignedUnitIds(user.assignedUnits);
      await _secureStorage.setAssignedRegionIds(user.assignedRegionIds);

      return Right(user);
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<Either<Failure, void>> updateFcmToken(String fcmToken) async {
    try {
      AppLogger.debug(
        '[FCM REPO] updateFcmToken start | '
        'tokenLength=${fcmToken.length} | '
        'hasNewLine=${fcmToken.contains('\n') || fcmToken.contains('\r')}',
      );
      final currentAccessToken = await _secureStorage.getToken();
      AppLogger.debug(
        '[FCM REPO] current access token | '
        'exists=${currentAccessToken != null && currentAccessToken.isNotEmpty} | '
        'length=${currentAccessToken?.length ?? 0} | '
        'hasNewLine=${(currentAccessToken?.contains('\n') ?? false) || (currentAccessToken?.contains('\r') ?? false)}',
      );
      final response = await _remoteDataSource.updateFcmToken(fcmToken);
      AppLogger.debug('Update FCM Token Response: $response');

      final hasExplicitFailure =
          response['success'] == false ||
          response['status'] == false ||
          response['error'] != null ||
          response['errors'] != null;

      if (!hasExplicitFailure) {
        return const Right(null);
      }
      return Left(
        ServerFailure(
          response['message']?.toString() ?? 'error_fcm_update',
        ),
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<Either<Failure, void>> removeFcmToken() async {
    try {
      await _remoteDataSource.removeFcmToken();
      return const Right(null);
    } catch (e) {
      return _handleError(e);
    }
  }

  Either<Failure, T> _handleError<T>(dynamic error) {
    AppLogger.error('Error: $error');
    if (error is Failure) return Left(error);
    if (error is DioException) return Left(ServerFailure.fromDioError(error));
    return Left(ServerFailure(AppErrorMessages.fromException(error)));
  }

  /// On a *login* request 400/401 always means "wrong username or password".
  /// The generic mapper turns 401 into "session expired, please log in again",
  /// which is nonsense on the login screen itself. Everything else (network,
  /// timeout, 5xx, 403) keeps its normal message.
  Either<Failure, T> _handleLoginError<T>(dynamic error) {
    AppLogger.error('Login error: $error');

    final kind = error is Failure
        ? AppErrorMessages.tryParseKind(error.errMessage)
        : null;
    final status = error is DioException ? error.response?.statusCode : null;

    if (kind == AppErrorKind.unauthorized ||
        kind == AppErrorKind.invalidData ||
        status == 400 ||
        status == 401) {
      return Left(ServerFailure('error_invalid_credentials'));
    }

    return _handleError(error);
  }
}

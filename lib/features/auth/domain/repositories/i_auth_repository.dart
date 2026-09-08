// lib/features/auth/domain/repositories/abstract/i_auth_repository.dart

import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/features/auth/domain/entities/user_entity.dart';

abstract class IAuthRepository {
  /// Send OTP to phone number (citizen login - step 1)
  Future<Either<Failure, void>> sendOtp(
    String phoneNumber, {
    bool rememberMe = true,
    String role = 'CITIZEN',
  });

  /// Verify OTP code (citizen login - step 2)
  Future<Either<Failure, UserEntity>> verifyOtp(
    String phoneNumber,
    String otpCode,
  );

  /// Employee login with username and password
  Future<Either<Failure, UserEntity>> employeeLogin(
    String username,
    String password, {
    required bool rememberMe,
  });

  /// Citizen login with username and password
  Future<Either<Failure, UserEntity>> citizenLogin(
    String username,
    String password,
  );

  Future<Either<Failure, UserEntity>> citizenRegister({
    required String username,
    required String fullName,
    required String password,
  });

  /// Logout from the system
  Future<Either<Failure, void>> logout({required String redirectUri});

  /// Fetch current user profile from API and update local storage
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Update FCM token for push notifications
  Future<Either<Failure, void>> updateFcmToken(String fcmToken);

  /// Remove FCM token for push notifications
  Future<Either<Failure, void>> removeFcmToken();
}

import 'package:qatrah/core/services/version_check_service.dart';

sealed class SplashState {}

final class SplashInitial extends SplashState {}

final class SplashLoading extends SplashState {}

final class SplashCompleted extends SplashState {}

final class SplashAuthenticated extends SplashState {
  SplashAuthenticated({required this.isEmployee, this.optionalUpdate});

  final bool isEmployee;

  /// A non-blocking update to offer once the user has landed.
  final VersionCheckResult? optionalUpdate;
}

final class SplashForceUpdate extends SplashState {
  SplashForceUpdate({this.storeUrl, this.apkUrl});

  final String? storeUrl;
  final String? apkUrl;
}

/// The server reported MAINTENANCE. [message] and [retryAfterSeconds] are
/// whatever the server sent, and may be absent.
final class SplashMaintenance extends SplashState {
  SplashMaintenance({this.message, this.retryAfterSeconds});

  final String? message;
  final int? retryAfterSeconds;
}

final class SplashUnauthenticated extends SplashState {
  SplashUnauthenticated({this.optionalUpdate});

  /// A non-blocking update to offer once the user has landed.
  final VersionCheckResult? optionalUpdate;
}

/// Employee session exists with PIN already configured — show the
/// local lock screen.
final class SplashEmployeeLocked extends SplashState {}

/// Employee session exists but no PIN was set yet — force PIN
/// creation before any protected screen.
final class SplashEmployeePinSetup extends SplashState {}

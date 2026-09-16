sealed class SplashState {}

final class SplashInitial extends SplashState {}

final class SplashLoading extends SplashState {}

final class SplashCompleted extends SplashState {}

final class SplashAuthenticated extends SplashState {
  SplashAuthenticated({required this.isEmployee});

  final bool isEmployee;
}

final class SplashForceUpdate extends SplashState {
  SplashForceUpdate({this.storeUrl, this.apkUrl});

  final String? storeUrl;
  final String? apkUrl;
}

final class SplashMaintenance extends SplashState {}

final class SplashUnauthenticated extends SplashState {}

/// Employee session exists with PIN already configured — show the
/// local lock screen.
final class SplashEmployeeLocked extends SplashState {}

/// Employee session exists but no PIN was set yet — force PIN
/// creation before any protected screen.
final class SplashEmployeePinSetup extends SplashState {}

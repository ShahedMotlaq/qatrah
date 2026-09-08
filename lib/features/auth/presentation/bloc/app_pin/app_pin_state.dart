part of 'app_pin_bloc.dart';

/// Stable error codes — UI maps to localized strings.
enum AppPinError {
  none,
  length,
  mismatch,
  invalid,
  notSet,
  locked,
  storage,
}

/// Which step we're currently on. Setup mode walks `enter → confirm`,
/// change mode walks `verifyCurrent → enter → confirm`, unlock stays on
/// `enter`.
enum AppPinStep { enter, confirm, verifyCurrent }

class AppPinState extends Equatable {
  const AppPinState({
    this.digits = '',
    this.firstPin = '',
    this.step = AppPinStep.enter,
    this.isLoading = false,
    this.error = AppPinError.none,
    this.completed = false,
    this.lockUntil,
    this.failedAttempts = 0,
    this.shouldClearSession = false,
  });

  final String digits;
  final String firstPin;
  final AppPinStep step;
  final bool isLoading;
  final AppPinError error;
  final bool completed;
  final DateTime? lockUntil;
  final int failedAttempts;
  final bool shouldClearSession;

  bool get isLocked => lockUntil != null && DateTime.now().isBefore(lockUntil!);

  AppPinState copyWith({
    String? digits,
    String? firstPin,
    AppPinStep? step,
    bool? isLoading,
    AppPinError? error,
    bool? completed,
    DateTime? lockUntil,
    bool clearLock = false,
    int? failedAttempts,
    bool? shouldClearSession,
  }) {
    return AppPinState(
      digits: digits ?? this.digits,
      firstPin: firstPin ?? this.firstPin,
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      completed: completed ?? this.completed,
      lockUntil: clearLock ? null : (lockUntil ?? this.lockUntil),
      failedAttempts: failedAttempts ?? this.failedAttempts,
      shouldClearSession: shouldClearSession ?? this.shouldClearSession,
    );
  }

  @override
  List<Object?> get props => [
    digits,
    firstPin,
    step,
    isLoading,
    error,
    completed,
    lockUntil,
    failedAttempts,
    shouldClearSession,
  ];
}

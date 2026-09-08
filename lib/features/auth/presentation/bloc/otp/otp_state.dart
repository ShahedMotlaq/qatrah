part of 'otp_bloc.dart';

@immutable
class OtpState {
  const OtpState({
    this.isLoading = false,
    this.isOtpSent = false,
    this.isVerified = false,
    this.errorMessage,
    // ── errorId ─────────────────────────────────────────────────────────────
    // A fresh [Object] is allocated on *every* error emission inside the bloc.
    // Because two distinct Object() instances are never identical (!=),
    // [BlocListener.listenWhen] can fire even when the *message* string is
    // identical to the previous error — solving the "once-off" trigger bug.
    this.errorId,
    // ────────────────────────────────────────────────────────────────────────
    this.timerDuration = 60,
    this.isTimerRunning = false,
    this.shouldCompleteProfile = false,
    this.isFromForgetPassword = false,
    this.retryLevel = 0,
    this.blockEndTime,
    this.serverRetryAfter,
  });

  final bool isLoading;
  final bool isOtpSent;
  final bool isVerified;
  final String? errorMessage;

  /// Unique token that changes with every error emission.
  /// Use this — not [errorMessage] — in [BlocListener.listenWhen].
  final Object? errorId;

  final int timerDuration;
  final bool isTimerRunning;
  final bool shouldCompleteProfile;
  final bool isFromForgetPassword;
  final int retryLevel;
  final DateTime? blockEndTime;
  final String? serverRetryAfter;

  OtpState copyWith({
    bool? isLoading,
    bool? isOtpSent,
    bool? isVerified,
    String? errorMessage,
    bool clearError = false,
    // Set to [true] when emitting a new error so [errorId] gets a fresh token.
    bool refreshErrorId = false,
    int? timerDuration,
    bool? isTimerRunning,
    bool? shouldCompleteProfile,
    bool? isFromForgetPassword,
    int? retryLevel,
    DateTime? blockEndTime,
    String? serverRetryAfter,
    bool clearServerRetryAfter = false,
  }) {
    return OtpState(
      isLoading: isLoading ?? this.isLoading,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      // Allocate a brand-new Object() when refreshErrorId is true; null it out
      // when the error is cleared; otherwise preserve the existing token.
      errorId: clearError ? null : (refreshErrorId ? Object() : errorId),
      timerDuration: timerDuration ?? this.timerDuration,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      shouldCompleteProfile:
          shouldCompleteProfile ?? this.shouldCompleteProfile,
      isFromForgetPassword: isFromForgetPassword ?? this.isFromForgetPassword,
      retryLevel: retryLevel ?? this.retryLevel,
      blockEndTime: blockEndTime ?? this.blockEndTime,
      serverRetryAfter: clearServerRetryAfter
          ? null
          : (serverRetryAfter ?? this.serverRetryAfter),
    );
  }
}

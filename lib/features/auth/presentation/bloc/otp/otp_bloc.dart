import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocListener;
import 'package:meta/meta.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/otp_timer_service.dart';
import 'package:qatrah/core/utils/app_logger.dart';
import 'package:qatrah/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:qatrah/features/auth/presentation/login_flow.dart';

part 'otp_event.dart';
part 'otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc() : super(const OtpState()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<StartTimerEvent>(_onStartTimer);
    on<ResumeOtpTimerEvent>(_onResumeOtpTimer);
    on<HandleRateLimitEvent>(_onHandleRateLimit);
    on<_TimerTicked>(_onTimerTicked);

    add(ResumeOtpTimerEvent());
  }

  final IAuthRepository _repository = getIt<IAuthRepository>();
  final SecureStorage _secureStorage = getIt<SecureStorage>();
  final OtpTimerService _otpTimerService = OtpTimerService();
  StreamSubscription<int>? _tickerSubscription;

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<OtpState> emit) async {
    final stillBlocked = await _otpTimerService.isBlocked();
    if (stillBlocked) {
      final remaining = await _otpTimerService.getRemainingSeconds();
      add(HandleRateLimitEvent(remaining));
      return;
    }

    if (!emit.isDone) {
      emit(
        state.copyWith(
          isLoading: true,
          isOtpSent: false,
          clearError: true,
        ),
      );
    }

    if (event.rememberMe) {
      await _secureStorage.setCitizenRememberMe(true);
      await _secureStorage.setCitizenPhone(event.phoneNumber.trim());
    } else {
      await _secureStorage.setCitizenRememberMe(false);
      await _secureStorage.deleteCitizenPhone();
    }

    final result = await _repository.sendOtp(event.phoneNumber.trim());

    await result.fold(
      (failure) async {
        final parsedRetryAfter = _extractRetryAfterSeconds(failure.errMessage);
        if (parsedRetryAfter != null && parsedRetryAfter > 0) {
          add(HandleRateLimitEvent(parsedRetryAfter));
          return;
        }

        if (!emit.isDone) {
          emit(
            state.copyWith(
              isLoading: false,
              errorMessage: failure.errMessage,
              // Refresh errorId so BlocListener fires even when the same
              // error string is repeated (fixes the "once-off" toast bug).
              refreshErrorId: true,
            ),
          );
        }
      },
      (_) async {
        await _secureStorage.setOtpRetryLevel(0);
        _startTimer(60);
        if (!emit.isDone) {
          emit(
            state.copyWith(
              isLoading: false,
              isOtpSent: true,
              isTimerRunning: true,
              timerDuration: 60,
              clearError: true,
              retryLevel: 0,
              clearServerRetryAfter: true,
            ),
          );
        }
      },
    );
  }

  Future<void> _onStartTimer(
    StartTimerEvent event,
    Emitter<OtpState> emit,
  ) async {
    _startTimer(event.duration);
    if (!emit.isDone) {
      emit(
        state.copyWith(
          isOtpSent: true,
          isTimerRunning: true,
          timerDuration: event.duration,
          clearError: true,
        ),
      );
    }
  }

  Future<void> _onResumeOtpTimer(
    ResumeOtpTimerEvent event,
    Emitter<OtpState> emit,
  ) async {
    final remaining = await _otpTimerService.getRemainingSeconds();
    final retryLevel = await _secureStorage.getOtpRetryLevel();
    final blockEndTime = await _secureStorage.getOtpBlockEndTime();

    if (remaining > 0) {
      _startTimer(remaining);
      if (!emit.isDone) {
        emit(
          state.copyWith(
            timerDuration: remaining,
            isTimerRunning: true,
            retryLevel: retryLevel,
            blockEndTime: blockEndTime,
          ),
        );
      }
      return;
    }

    await _otpTimerService.clearBlock();
  }

  Future<void> _onHandleRateLimit(
    HandleRateLimitEvent event,
    Emitter<OtpState> emit,
  ) async {
    final currentLevel = await _secureStorage.getOtpRetryLevel();
    final nextLevel = _otpTimerService.getNextRetryLevel(currentLevel);
    final levelSeconds = _otpTimerService.secondsForLevel(nextLevel);
    final serverSeconds = event.remainingSeconds > 0
        ? event.remainingSeconds
        : 0;
    // Prefer backend retry_after when provided so the UI shows the exact server
    // lock duration (e.g. 59s, 3m, 15m, 59m). Fallback to local backoff only
    // when the server value is missing.
    final blockedSeconds = serverSeconds > 0 ? serverSeconds : levelSeconds;

    await _secureStorage.setOtpRetryLevel(nextLevel);
    await _otpTimerService.startBlock(blockedSeconds, retryLevel: nextLevel);
    final blockEndTime = await _secureStorage.getOtpBlockEndTime();

    _startTimer(blockedSeconds);

    if (!emit.isDone) {
      emit(
        state.copyWith(
          isLoading: false,
          isTimerRunning: true,
          timerDuration: blockedSeconds,
          retryLevel: nextLevel,
          blockEndTime: blockEndTime,
          serverRetryAfter: blockedSeconds.toString(),
          errorMessage: 'otp_error_rate_limited',
          refreshErrorId: true,
        ),
      );
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<OtpState> emit,
  ) async {
    if (!emit.isDone) {
      emit(
        state.copyWith(isLoading: true, isVerified: false, clearError: true),
      );
    }

    final result = await _repository.verifyOtp(
      event.phoneNumber.trim(),
      event.otpCode.trim(),
    );

    await result.fold(
      (failure) async {
        if (!emit.isDone) {
          emit(
            state.copyWith(
              isLoading: false,
              isVerified: false,
              errorMessage: failure.errMessage,
              refreshErrorId: true,
            ),
          );
        }
      },
      (user) async {
        // The server has accepted the code and the repository has already
        // persisted the token — from here the login *has* happened. Bookkeeping
        // is therefore best-effort: it used to run inside a try that reported a
        // verified login as failed if any local write hiccuped, stranding the
        // user on the OTP screen with a perfectly valid session.
        try {
          await _otpTimerService.clearBlock();
          await _secureStorage.setOtpRetryLevel(0);
          await _tickerSubscription?.cancel();
        } catch (e) {
          AppLogger.error('OTP timer cleanup failed: $e');
        }

        // rememberMe is omitted on purpose: the choice was already recorded
        // when the code was sent.
        await completeLogin(
          kind: LoginKind.citizen,
          username: user.username,
        );

        if (emit.isDone) return;
        emit(
          state.copyWith(
            isLoading: false,
            isVerified: true,
            isTimerRunning: false,
            clearError: true,
            shouldCompleteProfile:
                !event.isFromForgetPassword && !user.profileComplete,
            isFromForgetPassword: event.isFromForgetPassword,
          ),
        );
      },
    );
  }

  void _onTimerTicked(_TimerTicked event, Emitter<OtpState> emit) {
    emit(
      state.copyWith(
        timerDuration: event.duration,
        isTimerRunning: event.duration > 0,
      ),
    );
  }

  void _startTimer(int duration) {
    _tickerSubscription?.cancel();
    add(_TimerTicked(duration));
    _tickerSubscription =
        Stream.periodic(
          const Duration(seconds: 1),
          (x) => duration - 1 - x,
        ).take(duration).listen((left) {
          add(_TimerTicked(left));
        });
  }

  int? _extractRetryAfterSeconds(String message) {
    final match = RegExp(
      r'retry[_\s-]*after[^0-9]*(\d+)',
      caseSensitive: false,
    ).firstMatch(message);
    if (match != null) return int.tryParse(match.group(1) ?? '');
    return null;
  }

  @override
  Future<void> close() async {
    await _tickerSubscription?.cancel();
    return super.close();
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/auth/pin_security_service.dart';

part 'app_pin_event.dart';
part 'app_pin_state.dart';

/// Mode the bloc operates in. The screens decide which one.
enum AppPinMode {
  /// First-time setup: enter, then confirm.
  setup,

  /// Unlock the app on resume / cold start.
  unlock,

  /// Change-PIN: verify current, then enter new, then confirm new.
  change,
}

class AppPinBloc extends Bloc<AppPinEvent, AppPinState> {
  AppPinBloc({
    required PinSecurityService pinService,
    required AppPinMode mode,
  }) : _pinService = pinService,
       _mode = mode,
       super(_initialState(mode)) {
    on<AppPinDigitsChanged>(_onDigits);
    on<AppPinSubmit>(_onSubmit);
    on<AppPinResetEntry>(_onResetEntry);
    on<_AppPinRestoreLock>(_onRestoreLock);

    if (mode == AppPinMode.unlock) {
      add(const _AppPinRestoreLock());
    }
  }

  final PinSecurityService _pinService;
  final AppPinMode _mode;

  static AppPinState _initialState(AppPinMode mode) {
    final step = mode == AppPinMode.change
        ? AppPinStep.verifyCurrent
        : AppPinStep.enter;
    return AppPinState(step: step);
  }

  Future<void> _onRestoreLock(
    _AppPinRestoreLock event,
    Emitter<AppPinState> emit,
  ) async {
    final until = await _pinService.activeLockUntil();
    if (until != null) {
      emit(state.copyWith(lockUntil: until));
    }
  }

  void _onDigits(AppPinDigitsChanged event, Emitter<AppPinState> emit) {
    emit(
      state.copyWith(
        digits: event.digits,
        error: AppPinError.none,
      ),
    );
  }

  void _onResetEntry(AppPinResetEntry event, Emitter<AppPinState> emit) {
    emit(
      AppPinState(
        step: _mode == AppPinMode.change
            ? AppPinStep.verifyCurrent
            : AppPinStep.enter,
      ),
    );
  }

  Future<void> _onSubmit(
    AppPinSubmit event,
    Emitter<AppPinState> emit,
  ) async {
    if (state.isLoading) return;

    final digits = state.digits;
    if (digits.length != PinSecurityService.pinLength) {
      emit(state.copyWith(error: AppPinError.length));
      return;
    }

    switch (_mode) {
      case AppPinMode.unlock:
        await _handleUnlock(digits, emit);
      case AppPinMode.setup:
        await _handleSetupStep(digits, emit);
      case AppPinMode.change:
        await _handleChangeStep(digits, emit);
    }
  }

  // ---------------- unlock ---------------------------------------------------
  Future<void> _handleUnlock(String pin, Emitter<AppPinState> emit) async {
    emit(state.copyWith(isLoading: true, error: AppPinError.none));
    final result = await _pinService.verify(pin);
    if (result.success) {
      emit(state.copyWith(isLoading: false, completed: true));
      return;
    }
    if (result.shouldClearSession) {
      emit(
        state.copyWith(
          isLoading: false,
          error: AppPinError.invalid,
          shouldClearSession: true,
          digits: '',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isLoading: false,
        error: result.lockUntil != null
            ? AppPinError.locked
            : AppPinError.invalid,
        digits: '',
        lockUntil: result.lockUntil,
        failedAttempts: result.failedAttempts,
      ),
    );
  }

  // ---------------- setup ----------------------------------------------------
  Future<void> _handleSetupStep(
    String pin,
    Emitter<AppPinState> emit,
  ) async {
    if (state.step == AppPinStep.enter) {
      final invalid = PinSecurityService.validatePinStrength(pin);
      if (invalid != null) {
        emit(
          state.copyWith(
            error: AppPinError.length,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          firstPin: pin,
          digits: '',
          step: AppPinStep.confirm,
        ),
      );
      return;
    }

    // Confirm step.
    if (pin != state.firstPin) {
      emit(
        state.copyWith(
          error: AppPinError.mismatch,
          digits: '',
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, error: AppPinError.none));
    try {
      await _pinService.setPin(pin);
      emit(state.copyWith(isLoading: false, completed: true));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: AppPinError.storage));
    }
  }

  // ---------------- change ---------------------------------------------------
  Future<void> _handleChangeStep(
    String pin,
    Emitter<AppPinState> emit,
  ) async {
    if (state.step == AppPinStep.verifyCurrent) {
      emit(state.copyWith(isLoading: true, error: AppPinError.none));
      final result = await _pinService.verify(pin);
      if (result.success) {
        emit(
          state.copyWith(
            isLoading: false,
            digits: '',
            step: AppPinStep.enter,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isLoading: false,
          error: result.lockUntil != null
              ? AppPinError.locked
              : AppPinError.invalid,
          digits: '',
          lockUntil: result.lockUntil,
          shouldClearSession: result.shouldClearSession,
        ),
      );
      return;
    }
    // After verifying current PIN, the rest of the change flow is identical
    // to setup.
    await _handleSetupStep(pin, emit);
  }
}

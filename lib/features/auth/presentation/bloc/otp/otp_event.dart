// lib/features/auth/presentation/bloc/otp/otp_event.dart

part of 'otp_bloc.dart';

@immutable
abstract class OtpEvent {}

class SendOtpEvent extends OtpEvent {
  SendOtpEvent(this.phoneNumber, {this.rememberMe = true});

  final String phoneNumber;

  /// Local only — whether to remember this phone on the device. The OTP
  /// request itself sends nothing but the number.
  final bool rememberMe;
}

class VerifyOtpEvent extends OtpEvent {
  VerifyOtpEvent(
    this.phoneNumber,
    this.otpCode, {
    this.isFromForgetPassword = false,
  });

  final String phoneNumber;
  final String otpCode;
  final bool isFromForgetPassword;
}

class StartTimerEvent extends OtpEvent {
  StartTimerEvent({this.duration = 60});

  final int duration;
}

class ResumeOtpTimerEvent extends OtpEvent {}

class HandleRateLimitEvent extends OtpEvent {
  HandleRateLimitEvent(this.remainingSeconds);

  final int remainingSeconds;
}

class _TimerTicked extends OtpEvent {
  _TimerTicked(this.duration);

  final int duration;
}

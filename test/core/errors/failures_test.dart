import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/core/errors/app_error_messages.dart';
import 'package:qatrah/core/errors/failures.dart';

void main() {
  test('429 OTP_RATE_LIMITED reads details.retryAfterSeconds', () {
    final failure = ServerFailure.fromResponse(429, {
      'code': 'OTP_RATE_LIMITED',
      'message': 'Too many requests',
      'details': {'retryAfterSeconds': 120},
    });

    expect(failure.errMessage, 'retry_after:120');
  });

  test('retryAfterSeconds sent as a string still parses', () {
    final failure = ServerFailure.fromResponse(429, {
      'code': 'OTP_RATE_LIMITED',
      'details': {'retryAfterSeconds': '45'},
    });

    expect(failure.errMessage, 'retry_after:45');
  });

  test('top-level retry_after still wins when present', () {
    final failure = ServerFailure.fromResponse(429, {
      'retry_after': 30,
      'details': {'retryAfterSeconds': 120},
    });

    expect(failure.errMessage, 'retry_after:30');
  });

  test('429 without a wait falls back to the generic rate-limit', () {
    final failure = ServerFailure.fromResponse(429, {
      'code': 'OTP_RATE_LIMITED',
      'details': <String, dynamic>{},
    });

    expect(failure.errMessage, isNot(startsWith('retry_after:')));
    expect(
      AppErrorMessages.tryParseKind(failure.errMessage),
      AppErrorKind.rateLimited,
    );
  });

  test('403 LOGIN_CHANNEL_NOT_ALLOWED maps to its own message', () {
    final failure = ServerFailure.fromResponse(403, {
      'code': 'LOGIN_CHANNEL_NOT_ALLOWED',
      'message': 'Admin accounts sign in on the web dashboard',
    });

    expect(failure.errorCode, 'LOGIN_CHANNEL_NOT_ALLOWED');
    expect(
      AppErrorMessages.tryParseKind(failure.errMessage),
      AppErrorKind.loginChannelNotAllowed,
    );
  });
}

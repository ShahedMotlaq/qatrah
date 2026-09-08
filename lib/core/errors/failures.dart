import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qatrah/core/errors/app_error_messages.dart';

abstract class Failure {
  const Failure(this.errMessage, {this.errorCode});
  final String errMessage;
  final String? errorCode;
}

class ServerFailure extends Failure {
  ServerFailure(super.errMessage, {super.errorCode});

  factory ServerFailure.fromResponse(int? statusCode, dynamic response) {
    String? msg;
    String? code;
    int? retryAfterSeconds;

    if (response is Map) {
      final retryAfter = response['retry_after'] ?? response['retryAfter'];
      if (retryAfter is num) {
        retryAfterSeconds = retryAfter.toInt();
      } else if (retryAfter is String) {
        retryAfterSeconds = int.tryParse(retryAfter.trim());
      }

      final err = response['error'];
      if (err is Map) {
        msg = err['message']?.toString();
        code = err['code']?.toString();
      } else {
        msg = err?.toString();
      }

      msg ??= response['message']?.toString();
      code ??= (response['code'] ?? response['errorCode'])?.toString();
    } else if (response is String) {
      msg = response;
    }

    // Surface known business error codes as domain keys so the UI can localize
    // them, instead of collapsing them into the generic 400 message.
    final businessKey = _businessErrorKey(code, msg);
    if (businessKey != null) {
      return ServerFailure(businessKey, errorCode: code);
    }

    if (retryAfterSeconds != null && retryAfterSeconds > 0) {
      return ServerFailure('retry_after:$retryAfterSeconds');
    }

    return ServerFailure(
      AppErrorMessages.fromStatusCode(statusCode, rawMessage: msg),
    );
  }

  factory ServerFailure.fromDioError(DioException dioError) {
    if (dioError.response == null) {
      final err = dioError.error;

      if (err is SocketException) {
        return ServerFailure.fromSocketException(err);
      }

      final msg = dioError.message ?? err?.toString() ?? '';
      if (msg.contains('SocketException')) {
        return ServerFailure.fromSocketException(
          err as SocketException? ?? SocketException(msg),
        );
      }

      return ServerFailure(
        AppErrorMessages.fromRaw(err?.toString() ?? msg, fallbackCode: 'A5'),
        errorCode: 'A5',
      );
    }

    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        return ServerFailure(
          AppErrorMessages.fromRaw('connection timeout'),
          errorCode: 'A2',
        );

      case DioExceptionType.sendTimeout:
        return ServerFailure(
          AppErrorMessages.fromRaw('send timeout'),
          errorCode: 'A2',
        );

      case DioExceptionType.receiveTimeout:
        return ServerFailure(
          AppErrorMessages.fromRaw('receive timeout'),
          errorCode: 'A2',
        );

      case DioExceptionType.badResponse:
        return ServerFailure.fromResponse(
          dioError.response?.statusCode,
          dioError.response?.data,
        );

      case DioExceptionType.cancel:
        return ServerFailure(
          AppErrorMessages.fromRaw('request canceled'),
          errorCode: 'A4',
        );

      case DioExceptionType.connectionError:
        final socketErr = dioError.error is SocketException
            ? dioError.error! as SocketException
            : null;
        if (socketErr != null) {
          return ServerFailure.fromSocketException(socketErr);
        }
        final msg = dioError.message ?? '';
        return ServerFailure(
          AppErrorMessages.fromRaw(msg, fallbackCode: 'A3'),
          errorCode: 'A3',
        );

      default:
        return ServerFailure(AppErrorMessages.unknown(), errorCode: 'U1');
    }
  }

  static ServerFailure fromSocketException(SocketException ex) {
    final osCode = ex.osError?.errorCode ?? 0;
    final msg = ex.message.toLowerCase();
    final osMsg = (ex.osError?.message ?? '').toLowerCase();
    final combined = '$msg $osMsg';

    // Windows error codes:
    // 11001-11004: DNS/hostname resolution failures (no internet)
    // 10051: Network unreachable
    // 10054: Connection reset by peer
    // 10060: Connection timed out
    // 10061: Connection refused (server down)
    // 10064: Host unreachable
    // 10065: No route to host

    final dnsCodes = {11001, 11002, 11003, 11004};
    final serverDownCodes = {10054, 10061, 10064, 10065};
    final networkUnreachableCodes = {10051};
    final timeoutCodes = {10060};

    if (dnsCodes.contains(osCode)) {
      return ServerFailure(
        AppErrorMessages.networkError(),
        errorCode: 'A1',
      );
    }

    if (timeoutCodes.contains(osCode)) {
      return ServerFailure(
        AppErrorMessages.timeoutError(),
        errorCode: 'A2',
      );
    }

    if (serverDownCodes.contains(osCode) ||
        networkUnreachableCodes.contains(osCode)) {
      return ServerFailure(
        AppErrorMessages.serverUnreachableError(),
        errorCode: 'A6',
      );
    }

    final dnsFailurePatterns = [
      'failed host lookup',
      'no address associated',
      'nodename nor servname',
      'name resolution',
      'temporary failure in name resolution',
    ];

    final serverUnreachablePatterns = [
      'connection refused',
      'target machine actively refused',
      'connection reset',
      'broken pipe',
      'connection aborted',
      'no route to host',
      'network is unreachable',
      'host is unreachable',
      'econnrefused',
    ];

    final timeoutPatterns = [
      'timed out',
      'connection timed out',
      'operation timed out',
    ];

    for (final pattern in dnsFailurePatterns) {
      if (combined.contains(pattern)) {
        return ServerFailure(
          AppErrorMessages.networkError(),
          errorCode: 'A1',
        );
      }
    }

    for (final pattern in timeoutPatterns) {
      if (combined.contains(pattern)) {
        return ServerFailure(
          AppErrorMessages.timeoutError(),
          errorCode: 'A2',
        );
      }
    }

    for (final pattern in serverUnreachablePatterns) {
      if (combined.contains(pattern)) {
        return ServerFailure(
          AppErrorMessages.serverUnreachableError(),
          errorCode: 'A6',
        );
      }
    }

    return ServerFailure(
      AppErrorMessages.serverUnreachableError(),
      errorCode: 'A6',
    );
  }

  /// Maps backend business error codes/messages to localizable domain keys.
  /// Returns `null` when no known business code is present.
  static String? _businessErrorKey(String? code, String? msg) {
    final haystack = '${code ?? ''} ${msg ?? ''}'.toUpperCase();
    if (haystack.contains('START_TIME_IN_FUTURE') ||
        haystack.contains('CANNOT_START_BEFORE_SCHEDULED_TIME')) {
      return 'cannotStartBeforeScheduledTime';
    }
    return null;
  }
}

class CacheFailure extends Failure {
  const CacheFailure(super.errMessage, {super.errorCode});
}

extension FailureExtension on Failure {
  bool get isAuthFailure {
    final msg = errMessage.toLowerCase();
    return msg.contains('401') ||
        msg.contains('unauthorized') ||
        msg.contains('token');
  }

  bool get isNetworkFailure {
    final encoded = AppErrorMessages.tryParseKind(errMessage);
    if (encoded != null) return encoded == AppErrorMessages.networkKind;
    final msg = errMessage.toLowerCase();
    return (msg.contains('internet') || msg.contains('network')) &&
        !msg.contains('refused') &&
        !msg.contains('reset') &&
        !msg.contains('unreachable');
  }

  bool get isServerError {
    final msg = errMessage.toLowerCase();
    return msg.contains('500') || msg.contains('server');
  }

  String getUserFriendlyMessage(BuildContext context) {
    return AppErrorMessages.userMessage(
      context,
      errMessage,
      fallbackCode: errorCode,
    );
  }
}

void showFailureSnackBar(BuildContext context, Failure failure) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(failure.getUserFriendlyMessage(context)),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
}

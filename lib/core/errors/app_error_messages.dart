import 'package:flutter/widgets.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

class AppErrorMessages {
  AppErrorMessages._();

  static const unknownCode = 'U1';
  static const _prefix = 'app_error';

  static String fromException(Object? error) {
    if (error == null) return unknown();
    return fromRaw(error.toString());
  }

  static String fromStatusCode(
    int? statusCode, {
    String? rawMessage,
    int? retryAfterSeconds,
  }) {
    if (retryAfterSeconds != null && retryAfterSeconds > 0) {
      return rateLimited(retryAfterSeconds);
    }

    if (_looksLikePayment(rawMessage)) return payment();

    return switch (statusCode) {
      400 || 422 => _encode(_ErrorKind.invalidData, 'S1'),
      401 => _encode(_ErrorKind.unauthorized, 'S2'),
      403 => _encode(_ErrorKind.forbidden, 'S3'),
      404 => _encode(_ErrorKind.notFound, 'S4'),
      408 => _encode(_ErrorKind.timeout, 'A2'),
      409 => _encode(_ErrorKind.invalidData, 'S8'),
      429 => _encode(_ErrorKind.rateLimited, 'S5'),
      500 || 502 || 503 || 504 => _encode(_ErrorKind.server, 'S6'),
      _ => fromRaw(rawMessage ?? ''),
    };
  }

  static String fromRaw(String message, {String? fallbackCode}) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return unknown(code: fallbackCode);
    if (_tryParse(trimmed) != null) return trimmed;

    final retryAfter = _extractRetryAfterSeconds(trimmed);
    if (retryAfter != null && retryAfter > 0) return rateLimited(retryAfter);

    if (_looksLikePayment(trimmed)) return payment();

    final lower = trimmed.toLowerCase();

    // Server unreachable (server is down/refusing) - check FIRST before network
    if (lower.contains('connection refused') ||
        lower.contains('target machine actively refused') ||
        lower.contains('connection reset') ||
        lower.contains('broken pipe') ||
        lower.contains('econnrefused') ||
        lower.contains('connection aborted') ||
        lower.contains('no route to host') ||
        lower.contains('network is unreachable') ||
        lower.contains('host is unreachable')) {
      return _encode(_ErrorKind.serverUnreachable, 'A6');
    }

    // DNS resolution failure (definitely no internet)
    if (lower.contains('failed host lookup') ||
        lower.contains('no address associated') ||
        lower.contains('nodename nor servname') ||
        lower.contains('name resolution')) {
      return _encode(_ErrorKind.network, 'A1');
    }

    // Timeout errors
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return _encode(_ErrorKind.timeout, 'A2');
    }

    // General socket/network errors - only clear internet connectivity issues
    if (lower.contains('socket') ||
        lower.contains('internet') ||
        lower.contains('failed host')) {
      return _encode(_ErrorKind.network, 'A1');
    }

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return _encode(_ErrorKind.timeout, 'A2');
    }

    if (lower.contains('cancel')) {
      return _encode(_ErrorKind.cancelled, 'A4');
    }

    if (lower.contains('unauthorized') ||
        lower.contains('invalid credential') ||
        lower.contains('invalid username') ||
        lower.contains('invalid password') ||
        lower.contains('401')) {
      return _encode(_ErrorKind.unauthorized, 'S2');
    }

    if (lower.contains('forbidden') || lower.contains('403')) {
      return _encode(_ErrorKind.forbidden, 'S3');
    }

    if (lower.contains('not found') || lower.contains('404')) {
      return _encode(_ErrorKind.notFound, 'S4');
    }

    if (lower.contains('rate') ||
        lower.contains('too many') ||
        lower.contains('429')) {
      return _encode(_ErrorKind.rateLimited, 'S5');
    }

    if (lower.contains('server') ||
        lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504')) {
      return _encode(_ErrorKind.server, 'S6');
    }

    if (lower.contains('bad request') ||
        lower.contains('validation') ||
        lower.contains('invalid') ||
        lower.contains('400') ||
        lower.contains('422')) {
      return _encode(_ErrorKind.invalidData, 'S1');
    }

    if (_containsLatinWords(trimmed)) return unknown(code: fallbackCode);

    return trimmed;
  }

  static String userMessage(
    BuildContext context,
    String message, {
    String? fallbackCode,
  }) {
    return localizedMessage(
      context.l10n,
      message,
      fallbackCode: fallbackCode,
    );
  }

  static String localizedMessage(
    AppLocalizations l10n,
    String message, {
    String? fallbackCode,
  }) {
    final trimmed = message.trim();
    final parsed = _tryParse(trimmed);
    if (parsed == null) {
      if (trimmed.isEmpty) {
        return _appendCode(l10n.errorOccurred, fallbackCode ?? unknownCode);
      }
      if (_containsLatinWords(trimmed)) {
        return _appendCode(l10n.errorOccurred, fallbackCode ?? unknownCode);
      }
      // Already a human-readable, localized message (a caller mapped it) —
      // don't tack a meaningless "U1" onto it.
      return fallbackCode == null
          ? trimmed
          : _appendCode(trimmed, fallbackCode);
    }

    final text = switch (parsed.kind) {
      _ErrorKind.network => l10n.noInternetConnection,
      _ErrorKind.serverUnreachable => l10n.serviceUnavailable,
      _ErrorKind.timeout => l10n.requestTimeoutError,
      _ErrorKind.cancelled => l10n.requestCancelledError,
      _ErrorKind.invalidData => l10n.invalidDataError,
      _ErrorKind.unauthorized => l10n.unauthorized,
      _ErrorKind.forbidden => l10n.forbidden,
      _ErrorKind.notFound => l10n.serviceUnavailable,
      _ErrorKind.rateLimited =>
        parsed.seconds == null
            ? l10n.loginTemporarilyDisabled
            : l10n.rateLimitedError(
                '${parsed.seconds}${l10n.secondsRemaining}',
              ),
      _ErrorKind.server => l10n.serverError,
      _ErrorKind.payment => l10n.paymentError,
      _ErrorKind.unknown => l10n.errorOccurred,
    };

    return _appendCode(text, parsed.code);
  }

  static bool isNetworkError(String message) {
    final parsed = _tryParse(message.trim());
    if (parsed != null) return parsed.kind == _ErrorKind.network;

    final lower = message.toLowerCase();
    return lower.contains('internet') ||
        lower.contains('network') ||
        lower.contains('socket');
  }

  static String unknown({String? code}) {
    return _encode(_ErrorKind.unknown, code ?? unknownCode);
  }

  static String payment() {
    return _encode(_ErrorKind.payment, 'B1');
  }

  static String rateLimited(int seconds) {
    return _encode(_ErrorKind.rateLimited, 'S5', seconds: seconds);
  }

  static String networkError({String code = 'A1'}) {
    return _encode(_ErrorKind.network, code);
  }

  static String serverUnreachableError({String code = 'A6'}) {
    return _encode(_ErrorKind.serverUnreachable, code);
  }

  static String timeoutError({String code = 'A2'}) {
    return _encode(_ErrorKind.timeout, code);
  }

  static String cancelledError({String code = 'A4'}) {
    return _encode(_ErrorKind.cancelled, code);
  }

  static AppErrorKind get networkKind => AppErrorKind.network;

  static AppErrorKind? tryParseKind(String message) {
    final parsed = _tryParse(message.trim());
    if (parsed != null) {
      return switch (parsed.kind) {
        _ErrorKind.network => AppErrorKind.network,
        _ErrorKind.serverUnreachable => AppErrorKind.serverUnreachable,
        _ErrorKind.timeout => AppErrorKind.timeout,
        _ErrorKind.cancelled => AppErrorKind.cancelled,
        _ErrorKind.invalidData => AppErrorKind.invalidData,
        _ErrorKind.unauthorized => AppErrorKind.unauthorized,
        _ErrorKind.forbidden => AppErrorKind.forbidden,
        _ErrorKind.notFound => AppErrorKind.notFound,
        _ErrorKind.rateLimited => AppErrorKind.rateLimited,
        _ErrorKind.server => AppErrorKind.server,
        _ErrorKind.payment => AppErrorKind.payment,
        _ErrorKind.unknown => AppErrorKind.unknown,
      };
    }
    return null;
  }

  static String _encode(_ErrorKind kind, String code, {int? seconds}) {
    final parts = [_prefix, kind.name, code];
    if (seconds != null) parts.add(seconds.toString());
    return parts.join('|');
  }

  static _ParsedError? _tryParse(String value) {
    final parts = value.split('|');
    if (parts.length < 3 || parts.first != _prefix) return null;
    _ErrorKind? kind;
    for (final candidate in _ErrorKind.values) {
      if (candidate.name == parts[1]) {
        kind = candidate;
        break;
      }
    }
    if (kind == null) return null;
    return _ParsedError(
      kind: kind,
      code: parts[2],
      seconds: parts.length > 3 ? int.tryParse(parts[3]) : null,
    );
  }

  static String _appendCode(String message, String? code) {
    if (code == null || code.trim().isEmpty) return message;
    if (RegExp(r'\([A-Z][0-9]+\)$').hasMatch(message.trim())) {
      return message.trim();
    }
    return '${message.trim()} ($code)';
  }

  static bool _containsLatinWords(String value) {
    return RegExp('[A-Za-z]{3,}').hasMatch(value);
  }

  static bool _looksLikePayment(String? value) {
    if (value == null) return false;
    final lower = value.toLowerCase();
    return lower.contains('payment') ||
        lower.contains('pay ') ||
        lower.contains('billing') ||
        lower.contains('invoice') ||
        lower.contains('checkout');
  }

  static int? _extractRetryAfterSeconds(String message) {
    final match = RegExp(
      r'retry[_\s-]*after[^0-9]*(\d+)',
      caseSensitive: false,
    ).firstMatch(message);
    if (match != null) return int.tryParse(match.group(1) ?? '');
    return null;
  }
}

enum AppErrorKind {
  network,
  serverUnreachable,
  timeout,
  cancelled,
  invalidData,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  server,
  payment,
  unknown,
}

enum _ErrorKind {
  network,
  serverUnreachable,
  timeout,
  cancelled,
  invalidData,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  server,
  payment,
  unknown,
}

class _ParsedError {
  const _ParsedError({
    required this.kind,
    required this.code,
    this.seconds,
  });

  final _ErrorKind kind;
  final String code;
  final int? seconds;
}

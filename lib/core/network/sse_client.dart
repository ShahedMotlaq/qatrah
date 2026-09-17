import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:qatrah/core/utils/app_logger.dart';

/// One dispatched server-sent event.
class SseEvent {
  const SseEvent({required this.event, required this.data, this.id});

  /// The `event:` field, or `message` when the server didn't name one.
  final String event;

  /// The joined `data:` lines.
  final String data;

  /// The `id:` field, replayed as `Last-Event-ID` after a drop.
  final String? id;
}

/// A server-sent events client over Dio.
///
/// The browser's `EventSource` can't send an `Authorization` header, so this
/// streams the response body instead and lets the usual interceptors attach
/// the bearer — including refreshing it on a 401.
///
/// [connect] keeps the stream alive across drops: the server closes an idle
/// stream after 30 minutes, and networks fail on their own. Each reconnect
/// sends the last id seen, so the server replays what was missed.
class SseClient {
  SseClient(this._dio);

  final Dio _dio;

  CancelToken? _cancelToken;
  bool _closed = false;

  /// Backoff between reconnects, capped so a long outage doesn't spin.
  static const _retryDelays = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

  Duration _retryDelay(int attempt) =>
      _retryDelays[attempt.clamp(0, _retryDelays.length - 1)];

  /// Opens [path] and yields events until the subscription is cancelled or
  /// [close] is called. Never yields an error: a drop is a reconnect, not a
  /// failure the screen has to handle.
  Stream<SseEvent> connect(String path, {String? lastEventId}) async* {
    var eventId = lastEventId;
    var attempt = 0;

    try {
      while (!_closed) {
        final cancelToken = CancelToken();
        _cancelToken = cancelToken;

        try {
          final response = await _dio.get<ResponseBody>(
            path,
            cancelToken: cancelToken,
            options: Options(
              responseType: ResponseType.stream,
              headers: {
                'Accept': 'text/event-stream',
                'Cache-Control': 'no-cache',
                'Last-Event-ID': ?eventId,
              },
              // A long-lived stream is idle between events by design, so the
              // usual receive timeout would kill it every few seconds.
              receiveTimeout: Duration.zero,
            ),
          );

          final body = response.data;
          if (body == null) throw StateError('empty SSE body');

          // Connected: the next drop starts its backoff from zero again.
          attempt = 0;

          await for (final event in _parse(body.stream)) {
            if (event.id != null && event.id!.isNotEmpty) eventId = event.id;
            yield event;
          }
        } catch (e) {
          if (_closed) return;
          if (e is DioException && CancelToken.isCancel(e)) return;
          if (_isPermanent(e)) {
            AppLogger.error('[SSE] $path refused, not retrying: $e');
            return;
          }
          AppLogger.error('[SSE] $path dropped: $e');
        }

        if (_closed) return;
        final delay = _retryDelay(attempt++);
        AppLogger.debug('[SSE] reconnecting to $path in ${delay.inSeconds}s');
        await Future<void>.delayed(delay);
      }
    } finally {
      _cancelToken?.cancel('stream closed');
      _cancelToken = null;
    }
  }

  /// A 4xx means the request itself is wrong — the caller isn't a citizen, or
  /// the location isn't theirs — and retrying it just burns battery. A 401 is
  /// excluded because the auth interceptor refreshes and retries it, and 408
  /// and 429 are worth another attempt.
  bool _isPermanent(Object error) {
    if (error is! DioException) return false;
    final status = error.response?.statusCode;
    if (status == null) return false;
    if (status == 401 || status == 408 || status == 429) return false;
    return status >= 400 && status < 500;
  }

  /// Stops reconnecting and aborts the request in flight. Call this when the
  /// screen closes, to save battery and a server connection.
  void close() {
    _closed = true;
    _cancelToken?.cancel('stream closed');
    _cancelToken = null;
  }

  /// Splits the byte stream into events per the SSE wire format: fields are
  /// `field: value` lines, a blank line dispatches, and a line starting with
  /// `:` is a comment — which is all a heartbeat is, so it never dispatches.
  Stream<SseEvent> _parse(Stream<List<int>> raw) async* {
    var event = 'message';
    String? id;
    final data = StringBuffer();

    // cast: the body arrives as Stream<Uint8List>, and utf8.decoder binds to
    // the exact element type at runtime.
    final lines = raw
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (line.isEmpty) {
        if (data.isNotEmpty) {
          yield SseEvent(event: event, data: data.toString(), id: id);
        }
        event = 'message';
        data.clear();
        continue;
      }

      if (line.startsWith(':')) continue;

      final separator = line.indexOf(':');
      final field = separator == -1 ? line : line.substring(0, separator);
      var value = separator == -1 ? '' : line.substring(separator + 1);
      if (value.startsWith(' ')) value = value.substring(1);

      switch (field) {
        case 'event':
          event = value;
        case 'id':
          id = value;
        case 'data':
          if (data.isNotEmpty) data.write('\n');
          data.write(value);
        // `retry` and unknown fields are ignored: the backoff above is ours.
      }
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/core/network/sse_client.dart';
import 'package:qatrah/features/home/data/realtime/pumping_stream_service.dart';

/// Serves one scripted SSE body per connection attempt, recording each request
/// so reconnect headers can be asserted.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.bodies);

  /// One entry per expected connection; `null` fails that connection.
  final List<String?> bodies;
  final List<RequestOptions> requests = <RequestOptions>[];
  int? refuseWith;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (refuseWith != null) {
      throw DioException(
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: refuseWith,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final index = requests.length - 1;
    final body = index < bodies.length ? bodies[index] : '';
    if (body == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }

    return ResponseBody(
      Stream<Uint8List>.value(Uint8List.fromList(utf8.encode(body))),
      200,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

SseClient _clientFor(_ScriptedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
    ..httpClientAdapter = adapter;
  return SseClient(dio);
}

/// One `pumping-event` frame.
String _run(int runId, int version, {String status = 'ACTIVE', String? id}) {
  final idLine = id == null ? '' : 'id: $id\n';
  return 'event: pumping-event\n$idLine'
      'data: {"runId":$runId,"status":"$status","version":$version}\n\n';
}

void main() {
  group('SseClient', () {
    test('parses named events, ids and data', () async {
      const body =
          'event: snapshot\ndata: {"lastEventId":812}\n\n'
          'event: pumping-event\nid: 813\ndata: {"runId":42}\n\n';
      final adapter = _ScriptedAdapter([body]);
      final client = _clientFor(adapter);

      final events = await client.connect('/stream').take(2).toList();
      client.close();

      expect(events[0].event, 'snapshot');
      expect(events[0].data, '{"lastEventId":812}');
      expect(events[0].id, isNull);
      expect(events[1].event, 'pumping-event');
      expect(events[1].id, '813');
    });

    test('heartbeat comments never dispatch', () async {
      const body =
          ': heartbeat\n\n'
          'event: pumping-event\ndata: {"runId":42}\n\n';
      final client = _clientFor(_ScriptedAdapter([body]));

      final first = await client.connect('/stream').first;
      client.close();

      expect(first.event, 'pumping-event');
    });

    test('multi-line data is joined', () async {
      final client = _clientFor(_ScriptedAdapter(['data: one\ndata: two\n\n']));

      final first = await client.connect('/stream').first;
      client.close();

      expect(first.data, 'one\ntwo');
      expect(first.event, 'message');
    });

    test('reconnect replays from the last id seen', () async {
      final adapter = _ScriptedAdapter([
        _run(42, 4, id: '813'),
        _run(42, 5, id: '814'),
      ]);
      final client = _clientFor(adapter);

      await client.connect('/stream').take(2).toList();
      client.close();

      expect(adapter.requests, hasLength(2));
      expect(adapter.requests[0].headers['Last-Event-ID'], isNull);
      expect(adapter.requests[1].headers['Last-Event-ID'], '813');
      expect(adapter.requests[0].headers['Accept'], 'text/event-stream');
    });

    test('a 403 ends the stream instead of retrying forever', () async {
      final adapter = _ScriptedAdapter([])..refuseWith = 403;
      final client = _clientFor(adapter);

      final events = await client.connect('/stream').toList();

      expect(events, isEmpty);
      expect(adapter.requests, hasLength(1), reason: 'no retry on a verdict');
    });
  });

  group('PumpingStreamService', () {
    Future<List<PumpingStreamMessage>> messagesFrom(String body) async {
      final service = PumpingStreamService(
        _clientFor(_ScriptedAdapter([body])),
      );
      final out = <PumpingStreamMessage>[];
      final done = Completer<void>();
      final sub = service.watch(15).listen(out.add);

      // The scripted body arrives in one chunk; give it a turn, then stop
      // before the reconnect backoff elapses.
      Timer(const Duration(milliseconds: 50), () async {
        service.close();
        await sub.cancel();
        done.complete();
      });

      await done.future;
      return out;
    }

    test('decodes the three payload events', () async {
      const payload =
          '{"eventId":813,"runId":42,"zoneId":4,"status":"PAUSED","version":4}';

      final messages = await messagesFrom(
        'event: snapshot\ndata: {"lastEventId":812}\n\n'
        'event: pumping-event\nid: 813\ndata: $payload\n\n'
        'event: resync-required\ndata: {"reason":"REPLAY_LIMIT_EXCEEDED"}\n\n',
      );

      expect(messages, hasLength(3));
      expect(messages[0], isA<PumpingSnapshot>());

      final update = messages[1] as PumpingRunUpdate;
      expect(update.runId, 42);
      expect(update.status, 'PAUSED');
      expect(update.version, 4);
      expect(update.zoneId, 4);

      expect(
        (messages[2] as PumpingResyncRequired).reason,
        'REPLAY_LIMIT_EXCEEDED',
      );
    });

    test('applies a run only when its version advances', () async {
      final messages = await messagesFrom(
        _run(42, 4) + _run(42, 4) + _run(42, 3) + _run(42, 5) + _run(43, 1),
      );

      expect(
        messages.cast<PumpingRunUpdate>().map((m) => '${m.runId}v${m.version}'),
        ['42v4', '42v5', '43v1'],
        reason: 'the duplicate and the stale event are dropped',
      );
    });

    test('a heartbeat or unknown event yields nothing', () async {
      final messages = await messagesFrom(
        ': heartbeat\n\nevent: something-else\ndata: {"a":1}\n\n',
      );

      expect(messages, isEmpty);
    });
  });
}

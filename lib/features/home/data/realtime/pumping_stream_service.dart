import 'dart:convert';

import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/sse_client.dart';
import 'package:qatrah/core/utils/app_logger.dart';

/// What the pumping stream tells a screen.
sealed class PumpingStreamMessage {
  const PumpingStreamMessage();
}

/// `snapshot` — the whole timeline, always sent first and after a reconnect.
/// Replace the screen state with it.
final class PumpingSnapshot extends PumpingStreamMessage {
  const PumpingSnapshot(this.timeline);

  /// `PumpingTimelineResponse`, raw: `location`, `current`, `next`, `recent`
  /// and `lastEventId`.
  final Map<String, dynamic> timeline;
}

/// `pumping-event` — one run changed.
final class PumpingRunUpdate extends PumpingStreamMessage {
  const PumpingRunUpdate({
    required this.eventId,
    required this.runId,
    required this.status,
    required this.version,
    this.zoneId,
  });

  final int eventId;
  final int runId;
  final String status;

  /// Increases with every change to the run; see [PumpingStreamService.watch].
  final int version;
  final int? zoneId;
}

/// `resync-required` — more than 200 events were missed. Re-fetch the
/// timeline, then reconnect without a `Last-Event-ID`.
final class PumpingResyncRequired extends PumpingStreamMessage {
  const PumpingResyncRequired(this.reason);

  final String reason;
}

/// Live pumping updates for one saved location.
///
/// `GET /me/locations/{locationId}/pumping-stream`, citizen-only. Staff have
/// no equivalent stream.
class PumpingStreamService {
  PumpingStreamService(this._client);

  final SseClient _client;

  /// The highest version seen per run. Delivery is at-least-once, so a payload
  /// that doesn't advance the version is a replay or an out-of-order dupe and
  /// is dropped rather than applied.
  final Map<int, int> _versions = <int, int>{};

  Stream<PumpingStreamMessage> watch(int locationId) async* {
    _versions.clear();

    await for (final event in _client.connect(
      ApiEndpoints.pumpingStream(locationId),
    )) {
      final message = _decode(event);
      if (message != null) yield message;
    }
  }

  /// Stops the stream. Call it when the screen closes.
  void close() => _client.close();

  PumpingStreamMessage? _decode(SseEvent event) {
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(event.data);
      if (decoded is! Map<String, dynamic>) return null;
      json = decoded;
    } catch (e) {
      AppLogger.error('[SSE] undecodable ${event.event} payload: $e');
      return null;
    }

    switch (event.event) {
      case 'snapshot':
        return PumpingSnapshot(json);

      case 'resync-required':
        return PumpingResyncRequired(
          json['reason']?.toString() ?? 'UNKNOWN',
        );

      case 'pumping-event':
        final runId = (json['runId'] as num?)?.toInt();
        final version = (json['version'] as num?)?.toInt();
        if (runId == null || version == null) return null;

        final seen = _versions[runId];
        if (seen != null && version <= seen) {
          AppLogger.debug(
            '[SSE] dropping run $runId v$version, already at v$seen',
          );
          return null;
        }
        _versions[runId] = version;

        return PumpingRunUpdate(
          eventId: (json['eventId'] as num?)?.toInt() ?? 0,
          runId: runId,
          status: json['status']?.toString() ?? '',
          version: version,
          zoneId: (json['zoneId'] as num?)?.toInt(),
        );

      // `heartbeat` never reaches here — it is a comment, not an event.
      default:
        return null;
    }
  }
}

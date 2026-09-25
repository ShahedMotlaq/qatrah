import 'package:dio/dio.dart';
import 'package:qatrah/core/config/env.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/network/sse_client.dart';

/// Live pumping updates for the operator.
///
/// `GET /staff/pumping-stream`. Runs on its own Dio and its own [SseClient],
/// so it shares no connection, state or interceptors with the citizen
/// `PumpingStreamService`.
class OperatorPumpingSseService {
  OperatorPumpingSseService(SecureStorage secureStorage)
    : _client = SseClient(
        Dio(BaseOptions(baseUrl: Env.baseUrl))
          ..interceptors.add(
            InterceptorsWrapper(
              // Read on every (re)connect, so a token refreshed elsewhere is
              // picked up on the next attempt.
              onRequest: (options, handler) async {
                final token = await secureStorage.getToken(role: 'OPERATOR');
                if (token != null && token.isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
                handler.next(options);
              },
            ),
          ),
      );

  static const String path = '/staff/pumping-stream';

  final SseClient _client;

  /// Raw events from the stream; reconnects on drops with `Last-Event-ID`.
  Stream<SseEvent> watch() => _client.connect(path);

  /// Stops the stream. Call it when the screen closes.
  void close() => _client.close();
}

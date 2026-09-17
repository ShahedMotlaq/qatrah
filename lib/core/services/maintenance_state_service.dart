import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';

/// `GET /server-state` — `{ "status": "OK", "message": "", "retryAfter": 0 }`.
///
/// While maintenance is on, every endpoint except this one and `/app-version`
/// answers `503` with this same body.
class ServerState {
  const ServerState({
    required this.isMaintenance,
    this.message,
    this.retryAfterSeconds,
  });

  factory ServerState.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? json['state'] ?? '')
        .toString()
        .toUpperCase();
    final message = json['message']?.toString();
    final retryAfter = json['retryAfter'] ?? json['retry_after'];

    return ServerState(
      isMaintenance: status == 'MAINTENANCE',
      message: message == null || message.trim().isEmpty ? null : message,
      retryAfterSeconds: switch (retryAfter) {
        final num n when n > 0 => n.toInt(),
        final String s => int.tryParse(s.trim()),
        _ => null,
      },
    );
  }

  /// Used when the check itself fails: a client that cannot reach
  /// `/server-state` must not lock the user out of a server that is fine.
  static const ok = ServerState(isMaintenance: false);

  final bool isMaintenance;

  /// Server-supplied text to show on the maintenance screen, when it sent one.
  final String? message;

  /// How long to wait before retrying, when the server said.
  final int? retryAfterSeconds;
}

class MaintenanceStateService {
  MaintenanceStateService({ApiService? apiService})
    : _apiService = apiService ?? getIt<ApiService>();

  final ApiService _apiService;

  Future<ServerState> fetch() async {
    try {
      final response = await _apiService.get(
        endPoint: ApiEndpoints.serverState,
      );
      final data = response['data'] ?? response;
      if (data is! Map<String, dynamic>) return ServerState.ok;
      return ServerState.fromJson(data);
    } catch (_) {
      return ServerState.ok;
    }
  }
}

import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';

class MaintenanceStateService {
  MaintenanceStateService({ApiService? apiService})
    : _apiService = apiService ?? getIt<ApiService>();

  final ApiService _apiService;

  Future<bool> isMaintenance() async {
    try {
      final response = await _apiService.get(
        endPoint: ApiEndpoints.serverState,
      );
      final data = response['data'] ?? response;
      final status = (data['status'] ?? data['state'] ?? '')
          .toString()
          .toLowerCase();
      return status == 'maintenance';
    } catch (_) {
      return false;
    }
  }
}

import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';

class VersionCheckResult {
  const VersionCheckResult({
    required this.forceUpdate,
    this.storeUrl,
    this.apkUrl,
  });

  final bool forceUpdate;
  final String? storeUrl;
  final String? apkUrl;
}

class VersionCheckService {
  VersionCheckService({ApiService? apiService})
    : _apiService = apiService ?? getIt<ApiService>();

  final ApiService _apiService;

  Future<VersionCheckResult> check() async {
    try {
      final response = await _apiService.get(endPoint: ApiEndpoints.appVersion);
      final data = response['data'] ?? response;
      final downloadUrl = data['downloadUrl']?.toString();
      return VersionCheckResult(
        forceUpdate: data['forceUpdate'] == true,
        storeUrl: data['storeUrl']?.toString(),
        apkUrl: data['apkUrl']?.toString() ?? downloadUrl,
      );
    } catch (_) {
      return const VersionCheckResult(forceUpdate: false);
    }
  }
}

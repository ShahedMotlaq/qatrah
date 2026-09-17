import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/utils/app_logger.dart';

class VersionCheckResult {
  const VersionCheckResult({
    required this.forceUpdate,
    this.updateAvailable = false,
    this.storeUrl,
    this.apkUrl,
    this.latestVersionName,
    this.releaseNotes,
  });

  factory VersionCheckResult.fromJson(Map<String, dynamic> json) {
    return VersionCheckResult(
      forceUpdate: json['forceUpdate'] == true,
      updateAvailable: json['updateAvailable'] == true,
      storeUrl: json['storeUrl']?.toString(),
      latestVersionName: _text(json['latestVersionName']),
      releaseNotes: _text(json['releaseNotes']),
      // Not part of the documented response; kept for the sideload build.
      apkUrl: json['apkUrl']?.toString() ?? json['downloadUrl']?.toString(),
    );
  }

  /// No policy configured, an unknown platform, or an unreachable server —
  /// none of which may block the launch.
  static const none = VersionCheckResult(forceUpdate: false);

  /// Block the app and send the user to [storeUrl].
  final bool forceUpdate;

  /// A newer build exists but this one still works — offer, don't block.
  final bool updateAvailable;

  final String? storeUrl;
  final String? apkUrl;

  /// e.g. "1.5.0" — shown in the optional-update dialog when present.
  final String? latestVersionName;
  final String? releaseNotes;

  /// Nothing to offer without somewhere to send the user.
  bool get canOfferUpdate =>
      updateAvailable && !forceUpdate && (storeUrl ?? apkUrl) != null;

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

/// `GET /app-version?platform=ANDROID&currentBuild=10400`.
///
/// Both query parameters are required: the server compares `currentBuild`
/// against the platform's `minimumSupportedBuild` to decide `forceUpdate`.
/// Sending neither asks the server a question it cannot answer.
class VersionCheckService {
  VersionCheckService({ApiService? apiService})
    : _apiService = apiService ?? getIt<ApiService>();

  final ApiService _apiService;

  Future<VersionCheckResult> check() async {
    // Only ANDROID and IOS are known to the server; anything else (web,
    // desktop, tests) has no policy to enforce.
    final platform = Platform.isAndroid
        ? 'ANDROID'
        : (Platform.isIOS ? 'IOS' : null);
    if (platform == null) return VersionCheckResult.none;

    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber.trim());
      if (currentBuild == null) {
        AppLogger.error(
          '[VERSION] unreadable build number "${info.buildNumber}" — skipping',
        );
        return VersionCheckResult.none;
      }

      final response = await _apiService.get(
        endPoint: ApiEndpoints.appVersion,
        queryParameters: {
          'platform': platform,
          'currentBuild': currentBuild,
        },
      );
      final data = response['data'] ?? response;
      if (data is! Map<String, dynamic>) return VersionCheckResult.none;

      return VersionCheckResult.fromJson(data);
    } catch (e) {
      // 404 APP_POLICY_NOT_FOUND means no policy is configured yet, and a
      // network failure must not strand the user on the splash either.
      // Both continue normally.
      AppLogger.error('[VERSION] check skipped: $e');
      return VersionCheckResult.none;
    }
  }
}

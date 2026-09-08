import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/utils/app_url_launcher.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';

class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({
    required this.storeUrl,
    required this.apkUrl,
    super.key,
  });

  final String? storeUrl;
  final String? apkUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final targetUrl = (storeUrl != null && storeUrl!.isNotEmpty)
        ? storeUrl
        : apkUrl;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.updateRequiredTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.updateRequiredMessage),
                const SizedBox(height: 20),
                AppButton(
                  text: l10n.updateNow,
                  onPressed: targetUrl == null
                      ? null
                      : () => _handleForceUpdate(context, targetUrl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleForceUpdate(BuildContext context, String url) async {
    if (!Platform.isAndroid) {
      await AppUrlLauncher.launchWebsite(context, url);
      return;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }
    } catch (_) {
      // Fall back to external URL / APK when in-app update is unavailable.
    }

    await AppUrlLauncher.launchWebsite(context, url);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/services/version_check_service.dart';
import 'package:qatrah/core/utils/app_url_launcher.dart';

/// Offers the update the server marked `updateAvailable` — the app still
/// works, so this is dismissible. A blocking `forceUpdate` goes to
/// `ForceUpdatePage` instead and never reaches here.
///
/// Shown once per cold start, since the version check itself runs once per
/// cold start.
Future<void> showOptionalUpdateDialog(
  BuildContext context,
  VersionCheckResult version,
) {
  final l10n = context.l10n;
  final url = version.storeUrl ?? version.apkUrl;
  if (url == null) return Future<void>.value();

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.updateAvailableTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.updateAvailableMessage),
            if (version.latestVersionName != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.updateAvailableVersion(version.latestVersionName!),
                style: Theme.of(dialogContext).textTheme.labelLarge,
              ),
            ],
            if (version.releaseNotes != null) ...[
              const SizedBox(height: 12),
              // Server-authored text; keep it scrollable so long notes can't
              // push the buttons off a small screen.
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Text(version.releaseNotes!),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.updateLater),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              unawaited(AppUrlLauncher.launchWebsite(context, url));
            },
            child: Text(l10n.updateNow),
          ),
        ],
      );
    },
  );
}

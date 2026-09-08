import 'package:flutter/material.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';

class AppUrlLauncher {
  AppUrlLauncher._();

  static Future<void> launchWebsite(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // LaunchMode.externalApplication
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError(context);
    }
  }

  /// Make a phone call
  static Future<void> makePhoneCall(
    BuildContext context,
    String phoneNumber,
  ) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError(context);
    }
  }

  /// Send an email
  static Future<void> sendEmail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError(context);
    }
  }

  /// Centralized error display when the system cannot open the link
  static void _showError(BuildContext context) {
    getIt<ToastService>().showError(context.l10n.cannotOpenLink);
  }
}

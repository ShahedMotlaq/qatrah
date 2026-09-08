// lib/core/widgets/app_toast.dart
//
// Backwards-compatible façade that forwards every call to [ToastService].
//
// Existing call-sites that import this file continue to work unchanged.
// New code should call [ToastService] directly via GetIt for a cleaner API.
//
// DEPRECATED API:
//   AppToast.show(context: context, message: msg, type: AppToastType.error);
//
// PREFERRED API:
//   getIt<ToastService>().showError(rawMessage);
//   getIt<ToastService>().showSuccess(localizedMessage);

import 'package:flutter/material.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';

/// Toast categories — mirrors the old enum so existing usages compile.
enum AppToastType { success, error, warning }

/// Static façade around [ToastService].
///
/// BuildContext is accepted but **not required** for the underlying toast to
/// render — it is only used to optionally update the [ToastService] l10n
/// reference before the call.
@Deprecated(
  'Call getIt<ToastService>() directly for a cleaner, context-free API.',
)
class AppToast {
  const AppToast._();

  static void show({
    required String message,
    BuildContext? context,
    AppToastType type = AppToastType.success,
  }) {
    final service = getIt<ToastService>();
    switch (type) {
      case AppToastType.error:
        service.showError(message);
      case AppToastType.success:
        service.showSuccess(message);
      case AppToastType.warning:
        service.showWarning(message);
    }
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qatrah/core/widgets/offline_state_widget.dart';

/// Unified failure view used across the app.
///
/// Always renders [OfflineStateWidget] — the approved branded error state.
class AppFailureView extends StatelessWidget {
  const AppFailureView({
    required this.message,
    super.key,
    this.onRetry,
  });

  final String message;
  final FutureOr<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return OfflineStateWidget(onRetry: onRetry);
  }
}

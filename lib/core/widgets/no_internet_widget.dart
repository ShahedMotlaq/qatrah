import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qatrah/core/widgets/offline_state_widget.dart';

class NoInternetWidget extends StatelessWidget {
  const NoInternetWidget({
    required this.onRetry,
    super.key,
    this.isRetrying = false,
  });

  final FutureOr<void> Function() onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    return OfflineStateWidget(
      onRetry: onRetry,
      isRetrying: isRetrying,
    );
  }
}

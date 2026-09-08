import 'package:flutter/material.dart';
import 'package:qatrah/core/theme/app_colors.dart';

/// A global custom RefreshIndicator for the Qatrah application.
///
/// This widget provides a consistent "Pull to Refresh" experience across the app.
/// It uses the official branding colors and a customized look.
///
/// Future Note: If you want to replace this with a more advanced animation like
/// 'LiquidPullToRefresh' or any custom Lottie-based animation, you can simply
/// modify the implementation within this file.
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    required this.child,
    required this.onRefresh,
    super.key,
  });

  /// The scrollable widget that will trigger the refresh.
  final Widget child;

  /// The callback function to be executed when the user pulls down to refresh.
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.darkPrimary,
      backgroundColor: AppColors.white.withValues(alpha: 0.95),
      child: child,
    );
  }
}

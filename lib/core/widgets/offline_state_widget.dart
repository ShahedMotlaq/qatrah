import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';

class OfflineStateWidget extends StatefulWidget {
  const OfflineStateWidget({
    this.onRetry,
    this.isRetrying = false,
    super.key,
  });

  final FutureOr<void> Function()? onRetry;
  final bool isRetrying;

  @override
  State<OfflineStateWidget> createState() => _OfflineStateWidgetState();
}

class _OfflineStateWidgetState extends State<OfflineStateWidget> {
  bool _isRetrying = false;

  bool get _showRetrying => widget.isRetrying || _isRetrying;

  Future<void> _retry() async {
    if (_showRetrying || widget.onRetry == null) return;
    setState(() => _isRetrying = true);
    try {
      await widget.onRetry!();
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: AppIconWidget(
                icon: HugeIcons.strokeRoundedWifiOff01,
                size: 48.sp,
                color: theme.colorScheme.error,
              ),
            ),
            24.verticalSpace,
            Text(
              l10n.noInternetConnection,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            8.verticalSpace,
            Text(
              l10n.networkError,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              32.verticalSpace,
              SizedBox(
                width: 220.w,
                child: _showRetrying
                    ? Center(
                        child: SizedBox(
                          width: 32.r,
                          height: 32.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      )
                    : AppButton(
                        text: l10n.retry,
                        onPressed: _retry,
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 18.sp,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

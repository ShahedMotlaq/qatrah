import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';

/// Full-screen blocked view shown when the user exceeds OTP retry limits.
class OtpBlockedView extends StatelessWidget {
  const OtpBlockedView({required this.timerDuration, super.key});

  final int timerDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final primary = theme.colorScheme.primary;
    final error = theme.colorScheme.error;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 32.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Layered glow circles + lock icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 116.r,
                  height: 116.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: error.withValues(alpha: 0.06),
                  ),
                ),
                Container(
                  width: 86.r,
                  height: 86.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: error.withValues(alpha: 0.11),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock_outline,
                      size: 40.sp,
                      color: error,
                    ),
                  ),
                ),
              ],
            ),
            28.verticalSpace,
            Text(
              l10n.otpBlockedTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            12.verticalSpace,
            Text(
              l10n.otpBlockedMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            32.verticalSpace,
            // Countdown card
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.otpBlockedWait,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  10.verticalSpace,
                  Text(
                    _formatCountdown(timerDuration),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCountdown(int seconds) {
    if (seconds >= 3600) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      final s = seconds % 60;
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

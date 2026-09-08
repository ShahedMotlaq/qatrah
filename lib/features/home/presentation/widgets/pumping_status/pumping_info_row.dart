// lib/features/home/presentation/widgets/pumping_status/pumping_info_row.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';

/// A single icon + label row used inside every pumping status card.
///
/// [label] is always a pre-localised string — the caller is responsible for
/// running it through `l10n` before passing it here.
class PumpingInfoRow extends StatelessWidget {
  const PumpingInfoRow({
    required this.icon,
    required this.label,
    this.accentColor,
    this.isBold = false,
    super.key,
  });

  final List<List<dynamic>> icon;
  final String label;

  /// When supplied the icon and text are tinted with this colour — used for
  /// the countdown row in the live card and the reason row in the cancelled card.
  final Color? accentColor;

  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = accentColor ?? theme.colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconWidget(
          icon: icon,
          size: 16.sp,
          color: effectiveColor,
          applyPadding: false,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: effectiveColor,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

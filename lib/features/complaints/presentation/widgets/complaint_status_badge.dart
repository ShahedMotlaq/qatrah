import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';

class ComplaintStatusBadge extends StatelessWidget {
  const ComplaintStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Color badgeColor;
    String badgeText;
    switch (status) {
      case 'IN_PROGRESS':
        badgeColor = Colors.blue.shade700;
        badgeText = l10n.statusInProgress;
      case 'RESOLVED':
        badgeColor = Colors.green.shade700;
        badgeText = l10n.statusResolved;
      case 'REJECTED':
        badgeColor = Colors.red.shade700;
        badgeText = l10n.statusRejected;
      case 'PENDING':
      default:
        badgeColor = Colors.orange.shade700;
        badgeText = l10n.statusPending;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12.sp,
        ),
      ),
    );
  }
}

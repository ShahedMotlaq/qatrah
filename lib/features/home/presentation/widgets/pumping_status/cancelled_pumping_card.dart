// lib/features/home/presentation/widgets/pumping_status/cancelled_pumping_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/theme/app_colors.dart';
import 'package:qatrah/core/utils/formatting_service.dart';
import 'package:qatrah/features/home/domain/entities/pumping_status_entity.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart'
    show HomeState, PumpingDisplayMode;
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_card_shell.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_info_row.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_status_badge.dart';

/// Displayed when [HomeState.pumpingDisplayMode] is [PumpingDisplayMode.cancelled].
///
/// Shows:
///   • Area name
///   • Original scheduled time range
///   • Cancellation reason (only when [session.cancelledReason] is non-empty)
///
/// All user-visible strings come from [l10n].
class CancelledPumpingCard extends StatelessWidget {
  const CancelledPumpingCard({required this.session, super.key});

  final PumpingStatusEntity session;

  static const Color _accentColor = AppColors.nude;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final end = session.endTime;

    final scheduledLabel = end != null
        ? '${l10n.scheduledForLabel}: ${FormattingService.formatScheduleEntry(l10n, session.startTime, end)}'
        : '${l10n.scheduledForLabel}: ${FormattingService.formatSmartDate(l10n, session.startTime)} | ${FormattingService.formatTime(session.startTime)}';

    return PumpingCardShell(
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CancelledTitleRow(
            title: l10n.pumpingCancelledTitle,
            badgeLabel: l10n.cancelledStatus,
            theme: theme,
          ),
          SizedBox(height: 10.h),
          PumpingInfoRow(
            icon: HugeIcons.strokeRoundedLocation01,
            label: session.areaPath.isNotEmpty
                ? session.areaPath
                : session.areaName,
          ),
          SizedBox(height: 6.h),
          PumpingInfoRow(
            icon: HugeIcons.strokeRoundedCalendar03,
            label: scheduledLabel,
          ),
          SizedBox(height: 6.h),
          PumpingInfoRow(
            icon: HugeIcons.strokeRoundedClock01,
            label:
                '${l10n.pumpingCancelledAt}: '
                '${FormattingService.formatSmartDate(l10n, session.startTime)} | '
                '${FormattingService.formatTime(session.startTime)}',
          ),
          if (_hasReason(session)) ...[
            SizedBox(height: 6.h),
            PumpingInfoRow(
              icon: HugeIcons.strokeRoundedInformationCircle,
              label:
                  '${l10n.cancellationReasonLabel}: ${session.cancelledReason}',
              accentColor: _accentColor,
            ),
          ],
        ],
      ),
    );
  }

  bool _hasReason(PumpingStatusEntity s) =>
      s.cancelledReason != null && s.cancelledReason!.trim().isNotEmpty;
}

class _CancelledTitleRow extends StatelessWidget {
  const _CancelledTitleRow({
    required this.title,
    required this.badgeLabel,
    required this.theme,
  });

  final String title;
  final String badgeLabel;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.cancel_rounded,
          color: AppColors.nude,
          size: 22.sp,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.nude,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PumpingStatusBadge(label: badgeLabel, color: AppColors.nude),
      ],
    );
  }
}

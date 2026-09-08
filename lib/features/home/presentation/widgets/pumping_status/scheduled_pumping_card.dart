import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/theme/app_colors.dart';
import 'package:qatrah/core/utils/formatting_service.dart';
import 'package:qatrah/features/home/domain/entities/pumping_status_entity.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_card_shell.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_info_row.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_status_badge.dart';

/// Displayed when the next upcoming scheduled pumping session is found.
/// Shows the scheduled time with countdown.
class ScheduledPumpingCard extends StatelessWidget {
  const ScheduledPumpingCard({
    required this.session,
    super.key,
  });

  final PumpingStatusEntity session;

  static const Color _accentColor = AppColors.warning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final end =
        session.endTime ?? session.startTime.add(const Duration(hours: 2));

    final scheduledLabel =
        '${l10n.scheduledForLabel}: '
        '${FormattingService.formatScheduleEntry(l10n, session.startTime, end)}';

    return PumpingCardShell(
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScheduledTitleRow(
            title: l10n.upcomingScheduledPumpingTitle,
            badgeLabel: l10n.scheduledStatus,
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
            icon: HugeIcons.strokeRoundedClock01,
            label: scheduledLabel,
          ),
          SizedBox(height: 6.h),
          PumpingInfoRow(
            icon: HugeIcons.strokeRoundedTimeSetting03,
            label:
                '${l10n.remainingTimeLabel} '
                '${FormattingService.formatTimeRemaining(l10n, session.startTime)}',
            accentColor: _accentColor,
            isBold: true,
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}

class _ScheduledTitleRow extends StatelessWidget {
  const _ScheduledTitleRow({
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
          Icons.schedule_rounded,
          color: AppColors.warning,
          size: 22.sp,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PumpingStatusBadge(label: badgeLabel, color: AppColors.warning),
      ],
    );
  }
}

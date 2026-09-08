// lib/features/home/presentation/widgets/pumping_status/live_pumping_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/theme/app_colors.dart';
import 'package:qatrah/core/utils/formatting_service.dart';
import 'package:qatrah/features/home/domain/entities/pumping_status_entity.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart'
    show HomeState, PumpingDisplayMode;
import 'package:qatrah/features/home/presentation/status_visuals.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pulsing_live_dot.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_card_shell.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_info_row.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_status_badge.dart';

/// Displayed when [HomeState.pumpingDisplayMode] is [PumpingDisplayMode.live].
///
/// Shows:
///   • Area name
///   • Start–end time range
///   • Countdown to end of pumping
///
/// All user-visible strings come from [l10n].  Time formatting goes through
/// [FormattingService] which also uses [l10n] for labels.
class LivePumpingCard extends StatelessWidget {
  const LivePumpingCard({required this.session, super.key});

  final PumpingStatusEntity session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final end =
        session.endTime ?? session.startTime.add(const Duration(hours: 2));
    final isPaused = session.status == PumpingStatus.paused;
    final accentColor = isPaused ? session.status.color : AppColors.success;

    return PumpingCardShell(
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleRow(
            title: isPaused ? l10n.pumpingPausedNow : l10n.livePumpingNow,
            badgeLabel: session.status.toLabel(l10n),
            accentColor: accentColor,
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
            label: FormattingService.formatScheduleEntry(
              l10n,
              session.startTime,
              end,
            ),
          ),
          SizedBox(height: 6.h),
          PumpingInfoRow(
            icon: HugeIcons.strokeRoundedTimeSetting03,
            label: FormattingService.formatTimeRemaining(l10n, end),
            accentColor: accentColor,
            isBold: true,
          ),
          if (session.status == PumpingStatus.paused &&
              _hasPauseReason(session)) ...[
            SizedBox(height: 6.h),
            PumpingInfoRow(
              icon: HugeIcons.strokeRoundedInformationCircle,
              label: '${l10n.pauseReasonLabel}: ${session.pauseReason}',
              accentColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }

  bool _hasPauseReason(PumpingStatusEntity s) =>
      s.pauseReason != null && s.pauseReason!.trim().isNotEmpty;
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.badgeLabel,
    required this.accentColor,
    required this.theme,
  });

  final String title;
  final String badgeLabel;
  final Color accentColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PulsingLiveDot(color: accentColor),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PumpingStatusBadge(label: badgeLabel, color: accentColor),
      ],
    );
  }
}

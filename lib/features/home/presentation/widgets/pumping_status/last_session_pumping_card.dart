// lib/features/home/presentation/widgets/pumping_status/last_session_pumping_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/utils/formatting_service.dart';
import 'package:qatrah/features/home/domain/entities/pumping_status_entity.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart'
    show HomeState, PumpingDisplayMode;
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_card_shell.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_info_row.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_status_badge.dart';

const _kLastSessionAccent = Color(0xFF8CA0B3);

/// Displayed when [HomeState.pumpingDisplayMode] is [PumpingDisplayMode.lastSession].
///
/// Shows the most recently completed pumping session: area name, when it ended,
/// and how long ago that was.
///
/// All user-visible strings come from [l10n].
class LastSessionPumpingCard extends StatelessWidget {
  const LastSessionPumpingCard({required this.session, super.key});

  final PumpingStatusEntity session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Prefer actual end time recorded by the backend; fall back to planned
    // end time so the card never shows an empty timestamp.
    final displayEndTime = session.actualEndTime ?? session.endTime;

    return PumpingCardShell(
      accentColor: _kLastSessionAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LastSessionTitleRow(
            title: l10n.lastPumpingSessionTitle,
            badgeLabel: l10n.completedStatus,
            theme: theme,
          ),
          SizedBox(height: 6.h),
          PumpingInfoRow(
            icon: HugeIcons.strokeRoundedLocation01,
            label: session.areaPath.isNotEmpty
                ? session.areaPath
                : session.areaName,
          ),
          if (displayEndTime != null) ...[
            SizedBox(height: 6.h),
            PumpingInfoRow(
              icon: HugeIcons.strokeRoundedTimeSetting03,
              label: FormattingService.formatDayDateTime(displayEndTime),
              accentColor: _kLastSessionAccent,
            ),
          ],
        ],
      ),
    );
  }
}

class _LastSessionTitleRow extends StatelessWidget {
  const _LastSessionTitleRow({
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
          Icons.check_circle_outline_rounded,
          color: _kLastSessionAccent,
          size: 16.sp,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _kLastSessionAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PumpingStatusBadge(label: badgeLabel, color: _kLastSessionAccent),
      ],
    );
  }
}

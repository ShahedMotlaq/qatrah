// lib/features/home/presentation/widgets/upcoming_schedules/upcoming_schedule_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/features/home/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/home/presentation/status_visuals.dart';
import 'package:qatrah/features/home/presentation/widgets/upcoming_schedules/schedule_details.dart';
import 'package:qatrah/features/home/presentation/widgets/upcoming_schedules/schedule_status_avatar.dart';
import 'package:qatrah/features/home/presentation/widgets/upcoming_schedules/schedule_status_pill.dart';

/// A single row inside the upcoming schedules list.
///
/// Displays:
///   • Status-coloured avatar icon
///   • Area name (bold)
///   • Formatted schedule time range (via FormattingService)
///   • Optional notes line
///   • Status badge pill on the trailing side
///
/// All strings come from l10n (via `context.l10n`) or FormattingService.
/// No hardcoded text anywhere.
class UpcomingScheduleItem extends StatelessWidget {
  const UpcomingScheduleItem({required this.schedule, super.key});

  final ScheduleEntity schedule;

  @override
  Widget build(BuildContext context) {
    final status = schedule.currentStatus;
    final statusColor = status.color;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          ScheduleStatusAvatar(
            schedule: schedule,
            statusColor: statusColor,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ScheduleDetails(
              schedule: schedule,
              theme: Theme.of(context),
            ),
          ),
          SizedBox(width: 12.w),
          ScheduleStatusPill(
            label: status.toLabel(context.l10n),
            color: statusColor,
            theme: Theme.of(context),
          ),
        ],
      ),
    );
  }
}

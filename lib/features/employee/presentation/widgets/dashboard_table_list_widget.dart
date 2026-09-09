import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/utils/app_date_formatter.dart';
import 'package:qatrah/core/widgets/app_empty_state_widget.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';
import 'package:qatrah/features/employee/presentation/widgets/schedule_status_badge_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/schedule_table_action_cell_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Card-based list of the filtered schedules (replaces the old DataTable).
class DashboardTableListWidget extends StatelessWidget {
  const DashboardTableListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (p, c) =>
          p.filteredSchedules != c.filteredSchedules ||
          p.isLoading != c.isLoading,
      builder: (context, state) {
        if (state.filteredSchedules.isEmpty) {
          return SliverToBoxAdapter(
            child: Skeletonizer(
              enabled: state.isLoading,
              child: AppEmptyState(
                message: l10n.noSchedulesFound,
                icon: HugeIcons.strokeRoundedCalendar01,
              ),
            ),
          );
        }

        return SliverToBoxAdapter(
          child: Skeletonizer(
            enabled: state.isLoading,
            child: Column(
              children: [
                for (final schedule in state.filteredSchedules)
                  _ScheduleCard(schedule: schedule),
                12.verticalSpace,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});

  final ScheduleEntity schedule;

  static const _statusesWithActions = {'SCHEDULED', 'ACTIVE', 'PAUSED'};

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'SCHEDULED':
        return Colors.blue;
      case 'ACTIVE':
        return Colors.green;
      case 'PAUSED':
        return const Color(0xFFF5A623);
      case 'COMPLETED':
        return Colors.grey;
      case 'CANCELLED':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _statusLabel(String status, BuildContext context) {
    final l10n = context.l10n;
    switch (status) {
      case 'SCHEDULED':
        return l10n.scheduled;
      case 'ACTIVE':
        return l10n.active;
      case 'PAUSED':
        return l10n.pausedStatus;
      case 'COMPLETED':
        return l10n.finished;
      case 'CANCELLED':
        return l10n.cancelled;
      default:
        return status;
    }
  }

  /// Cancellation / pause reason takes priority over free notes.
  (String label, String text)? _note(BuildContext context) {
    final l10n = context.l10n;
    final reason = switch (schedule.status.toUpperCase()) {
      'CANCELLED' => (
        l10n.cancellationReasonLabel,
        schedule.cancellationReason,
      ),
      'PAUSED' => (l10n.pauseReasonLabel, schedule.pauseReason),
      _ => (l10n.notes, null),
    };
    if (reason.$2?.isNotEmpty ?? false) return (reason.$1, reason.$2!);
    if (schedule.notes?.isNotEmpty ?? false) {
      return (l10n.notes, schedule.notes!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final status = schedule.status.toUpperCase();
    final statusColor = _statusColor(status, theme);
    final note = _note(context);

    // Only the last segment of the location chain — the deepest name the
    // schedule carries. The rest of the path adds nothing on a phone card.
    final location =
        [
          schedule.zoneName,
          schedule.neighborhoodName,
          schedule.unitName,
        ].whereType<String>().firstWhere(
          (e) => e.isNotEmpty,
          orElse: () => schedule.regionName,
        );

    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- Header ----------
          Row(
            children: [
              Expanded(
                child: Text(
                  location,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              8.horizontalSpace,
              ScheduleStatusBadgeWidget(
                statusColor: statusColor,
                label: _statusLabel(status, context),
              ),
            ],
          ),
          // ---------- Body: start / end time ----------
          16.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _TimeInfo(
                  icon: HugeIcons.strokeRoundedPlayCircle02,
                  label: l10n.startPumpingLabel,
                  dateTime: schedule.startTime,
                  color: const Color(0xFF1B4D3E),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: _TimeInfo(
                  icon: HugeIcons.strokeRoundedStop,
                  label: l10n.endPumpingLabel,
                  dateTime: schedule.actualEndTime ?? schedule.endTime,
                  color: const Color(0xFFE65100),
                ),
              ),
            ],
          ),

          // ---------- Duration indicator ----------
          12.verticalSpace,
          _DurationIndicator(schedule: schedule, status: status),

          // ---------- Notes (hidden when empty) ----------
          if (note != null) ...[
            12.verticalSpace,
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedNote,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                    strokeWidth: 1.5,
                  ),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      '${note.$1}: ${note.$2}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ---------- Actions footer ----------
          if (_statusesWithActions.contains(status)) ...[
            12.verticalSpace,
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
            8.verticalSpace,
            ScheduleTableActionCellWidget(
              status: status,
              scheduleId: schedule.id,
              schedule: schedule,
            ),
          ],
        ],
      ),
    );
  }
}

/// Fraction (0..1) of the scheduled window that has elapsed at [now].
/// Terminal statuses read as full, not-yet-started ones as empty.
double scheduleElapsedFraction(
  ScheduleEntity schedule,
  String status,
  DateTime now,
) {
  final upper = status.toUpperCase();
  if (upper == 'COMPLETED' || upper == 'CANCELLED') return 1;
  if (upper == 'SCHEDULED') return 0;
  final total = schedule.endTime.difference(schedule.startTime).inSeconds;
  if (total <= 0) return 1;
  return (now.difference(schedule.startTime).inSeconds / total).clamp(0.0, 1.0);
}

/// Pie chart showing how much of the scheduled window has elapsed.
///
/// ponytail: snapshot, not a ticking clock — it repaints when the bloc emits.
/// Add a Timer.periodic here if operators need a live-advancing slice.
class _DurationIndicator extends StatelessWidget {
  const _DurationIndicator({required this.schedule, required this.status});

  final ScheduleEntity schedule;
  final String status;

  String _durationText(BuildContext context) {
    final l10n = context.l10n;
    final total = schedule.endTime.difference(schedule.startTime);
    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60);
    if (hours <= 0) return l10n.durationMinutes(minutes);
    if (minutes == 0) return l10n.durationHours(hours);
    return l10n.durationHoursAndMinutes(
      l10n.durationHours(hours),
      l10n.durationMinutes(minutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final progress = scheduleElapsedFraction(schedule, status, DateTime.now());

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          CustomPaint(
            size: Size(36.w, 36.w),
            painter: _PiePainter(
              progress: progress,
              color: theme.colorScheme.primary,
              trackColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.durationIndicatorLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                2.verticalSpace,
                Text(
                  _durationText(context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  const _PiePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas
      ..drawCircle(
        rect.center,
        size.shortestSide / 2,
        Paint()..color = trackColor,
      )
      ..drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        true,
        Paint()..color = color,
      );
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.progress != progress || old.color != color;
}

class _TimeInfo extends StatelessWidget {
  const _TimeInfo({
    required this.icon,
    required this.label,
    required this.dateTime,
    required this.color,
  });

  final List<List<dynamic>> icon;
  final String label;
  final DateTime dateTime;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: HugeIcon(icon: icon, size: 16, color: color, strokeWidth: 1.5),
        ),
        8.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              2.verticalSpace,
              Text(
                AppDateFormatter.formatNotificationDateTime(dateTime, context),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

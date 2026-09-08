import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/utils/formatting_service.dart';
import 'package:qatrah/features/home/domain/entities/schedule_entity.dart';

/// Central detail column for a schedule row (area name, time, notes).
class ScheduleDetails extends StatelessWidget {
  const ScheduleDetails({
    required this.schedule,
    required this.theme,
    super.key,
  });

  final ScheduleEntity schedule;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          schedule.areaName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        _TimeRow(schedule: schedule, theme: theme),
        if (_hasNotes) _NotesRow(notes: schedule.notes!, theme: theme),
      ],
    );
  }

  bool get _hasNotes =>
      schedule.notes != null && schedule.notes!.trim().isNotEmpty;
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.schedule, required this.theme});

  final ScheduleEntity schedule;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            FormattingService.formatScheduleEntry(
              context.l10n,
              schedule.startTime,
              schedule.endTime,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesRow extends StatelessWidget {
  const _NotesRow({required this.notes, required this.theme});

  final String notes;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.notes_rounded,
          size: 13,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            notes,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

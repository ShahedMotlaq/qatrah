import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/features/home/domain/entities/schedule_entity.dart';

/// Status-coloured avatar icon for a schedule row.
class ScheduleStatusAvatar extends StatelessWidget {
  const ScheduleStatusAvatar({
    required this.schedule,
    required this.statusColor,
    super.key,
  });

  final ScheduleEntity schedule;
  final Color statusColor;

  List<List<dynamic>> get _icon {
    if (schedule.isOngoing) return HugeIcons.strokeRoundedPlay;
    if (schedule.isUpcoming) return HugeIcons.strokeRoundedTimeSetting03;
    return HugeIcons.strokeRoundedCheckmarkBadge04;
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: statusColor.withValues(alpha: 0.2),
      child: AppIconWidget(icon: _icon, color: statusColor),
    );
  }
}

// lib/features/home/presentation/widgets/upcoming_schedules_widget.dart
//
// Thin coordinator widget for the "Upcoming Schedules" section.
// All item rendering is delegated to UpcomingScheduleItem.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_empty_state_widget.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/features/home/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart';
import 'package:qatrah/features/home/presentation/widgets/upcoming_schedules/upcoming_schedule_item.dart';

class UpcomingSchedulesWidget extends StatelessWidget {
  const UpcomingSchedulesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (prev, curr) => prev.schedules != curr.schedules,
      builder: (context, state) {
        final now = DateTime.now();
        final upcoming = state.schedules
            .where(
              (s) =>
                  s.currentStatus == ScheduleStatus.scheduled &&
                  s.startTime.isAfter(now),
            )
            .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              const _SchedulesSectionHeader(),
              if (upcoming.isEmpty)
                const _SchedulesEmptyState()
              else
                _SchedulesList(schedules: upcoming),
            ],
          ),
        );
      },
    );
  }
}

class _SchedulesSectionHeader extends StatelessWidget {
  const _SchedulesSectionHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFB89E6E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          AppIconWidget(
            icon: HugeIcons.strokeRoundedCalendar03,
            color: theme.colorScheme.onPrimary,
          ),
          Text(
            context.l10n.upcomingSchedules,
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SchedulesList extends StatelessWidget {
  const _SchedulesList({required this.schedules});
  final List<ScheduleEntity> schedules;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        children: schedules
            .take(5)
            .map((s) => UpcomingScheduleItem(schedule: s))
            .toList(),
      ),
    );
  }
}

class _SchedulesEmptyState extends StatelessWidget {
  const _SchedulesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: AppEmptyState(
        message: context.l10n.noSchedulesMessage,
        icon: HugeIcons.strokeRoundedCalendarRemove01,
      ),
    );
  }
}

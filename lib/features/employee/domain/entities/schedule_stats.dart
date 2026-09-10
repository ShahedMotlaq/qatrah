import 'package:equatable/equatable.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';

/// Pumping statistics over a rolling 24-hour cycle ending at `now`.
///
///  • [active] / [paused]: live counts right now, regardless of the window.
///  • [upcoming]: SCHEDULED sessions starting within the next 24 hours.
///  • [completed]: sessions that finished within the last 24 hours.
///  • [cancelled]: cancelled sessions that were due within the last 24 hours
///    (the API exposes no cancellation timestamp).
///  • [pumpingTime]: water actually delivered inside the last 24 hours —
///    completed and still-active sessions, clipped to the window.
class ScheduleStats extends Equatable {
  const ScheduleStats({
    this.active = 0,
    this.paused = 0,
    this.upcoming = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.pumpingTime = Duration.zero,
  });

  factory ScheduleStats.fromSchedules(
    Iterable<ScheduleEntity> schedules,
    DateTime now,
  ) {
    const cycle = Duration(hours: 24);
    final windowStart = now.subtract(cycle);
    final windowEnd = now.add(cycle);
    bool inLastCycle(DateTime t) => !t.isBefore(windowStart) && !t.isAfter(now);

    // Portion of [from, to] that falls inside [windowStart, now].
    Duration overlap(DateTime from, DateTime to) {
      final start = from.isAfter(windowStart) ? from : windowStart;
      final end = to.isBefore(now) ? to : now;
      return end.isAfter(start) ? end.difference(start) : Duration.zero;
    }

    var active = 0;
    var paused = 0;
    var upcoming = 0;
    var completed = 0;
    var cancelled = 0;
    var pumpingTime = Duration.zero;

    for (final s in schedules) {
      switch (s.status.toUpperCase()) {
        case 'ACTIVE':
          active++;
          pumpingTime += overlap(s.startTime, now);
        case 'PAUSED':
          // No pause timestamp from the API, so its delivered time is unknown.
          paused++;
        case 'SCHEDULED':
          if (s.startTime.isAfter(now) && !s.startTime.isAfter(windowEnd)) {
            upcoming++;
          }
        case 'COMPLETED':
          final end = s.actualEndTime ?? s.endTime;
          if (inLastCycle(end)) completed++;
          pumpingTime += overlap(s.startTime, end);
        case 'CANCELLED':
          if (inLastCycle(s.startTime)) cancelled++;
      }
    }

    return ScheduleStats(
      active: active,
      paused: paused,
      upcoming: upcoming,
      completed: completed,
      cancelled: cancelled,
      pumpingTime: pumpingTime,
    );
  }

  final int active;
  final int paused;
  final int upcoming;
  final int completed;
  final int cancelled;
  final Duration pumpingTime;

  @override
  List<Object?> get props => [
    active,
    paused,
    upcoming,
    completed,
    cancelled,
    pumpingTime,
  ];
}

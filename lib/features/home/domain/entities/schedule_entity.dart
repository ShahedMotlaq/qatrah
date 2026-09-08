// lib/features/home/domain/entities/schedule_entity.dart

class ScheduleEntity {
  const ScheduleEntity({
    required this.id,
    required this.areaName,
    required this.areaPath,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.regionId,
    this.unitId,
    this.neighborhoodId,
    this.zoneId,
    this.actualEndTime,
    this.notes,
    this.cancelledReason,
    this.pauseReason,
  });

  final int id;
  final int? regionId;
  final int? unitId;
  final int? neighborhoodId;
  final int? zoneId;
  final String areaName;
  final String areaPath;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? actualEndTime;
  final ScheduleStatus status;
  final String? notes;

  /// Reason provided by the operator when a schedule is cancelled.
  /// Mapped from the API fields: `cancelledReason`, `cancellationReason`, or
  /// `reason`. Distinct from [notes] which is a general scheduling annotation.
  final String? cancelledReason;

  /// Reason provided by the operator when a schedule is paused.
  /// Mapped from the API fields: `pauseReason` or `pausedReason`. Distinct from
  /// [cancelledReason] which applies to cancelled schedules.
  final String? pauseReason;

  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isOngoing =>
      startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());
  bool get isFinished => endTime.isBefore(DateTime.now());

  /// Dynamic status based on current time and API-provided status.
  /// Respects terminal API statuses (cancelled, completed) so that a
  /// stale [endTime] does not keep a finished schedule looking active.
  ScheduleStatus get currentStatus {
    final now = DateTime.now();
    if (status == ScheduleStatus.cancelled) return ScheduleStatus.cancelled;
    if (status == ScheduleStatus.completed) return ScheduleStatus.completed;
    if (status == ScheduleStatus.paused) return ScheduleStatus.paused;
    if (now.isAfter(startTime) && now.isBefore(endTime)) {
      return ScheduleStatus.active;
    }
    if (now.isBefore(startTime)) return ScheduleStatus.scheduled;
    return ScheduleStatus.completed;
  }
}

enum ScheduleStatus {
  scheduled,
  active,
  paused,
  completed,
  cancelled,
}

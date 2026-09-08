// lib/features/home/domain/entities/pumping_status_entity.dart

class PumpingStatusEntity {
  const PumpingStatusEntity({
    required this.scheduleId,
    required this.areaName,
    required this.areaPath,
    required this.startTime,
    required this.status,
    this.endTime,
    this.actualEndTime,
    this.hasFeedback = false,
    this.cancelledReason,
    this.pauseReason,
    this.temporaryFailure = false,
  });

  final int scheduleId;
  final String areaName;
  final String areaPath;
  final DateTime startTime;
  final DateTime? endTime;

  /// Actual end time recorded when the schedule was completed.
  /// Separate from [endTime] (planned end) so the UI can show the
  /// real completion timestamp when available.
  final DateTime? actualEndTime;
  final PumpingStatus status;
  final bool hasFeedback;

  /// Human-readable reason for cancellation, populated when [status] is
  /// [PumpingStatus.cancelled]. Surfaced directly on the UI card.
  final String? cancelledReason;

  /// Human-readable reason for pausing, populated when [status] is
  /// [PumpingStatus.paused]. Surfaced directly on the UI card.
  final String? pauseReason;

  /// Whether the schedule is temporarily stopped (e.g., technical issue).
  /// True when status == [PumpingStatus.paused].
  final bool temporaryFailure;

  bool get isActive => status == PumpingStatus.active;
  bool get isPaused => status == PumpingStatus.paused;
  bool get isScheduled => status == PumpingStatus.scheduled;
  bool get isCompleted => status == PumpingStatus.completed;
  bool get isCancelled => status == PumpingStatus.cancelled;

  /// Check if the current time is within the scheduled pumping period
  bool get isWithinScheduledTime {
    if (!isScheduled) return false;
    final now = DateTime.now();
    final end = endTime ?? startTime.add(const Duration(hours: 2));
    return now.isAfter(startTime) && now.isBefore(end);
  }

  /// A scheduled session whose time window has passed (for display as completed)
  bool get isScheduledPastTime {
    if (!isScheduled) return false;
    final now = DateTime.now();
    final end = endTime ?? startTime.add(const Duration(hours: 2));
    return now.isAfter(end);
  }

  /// Check if the current time is within a cancelled period's window
  bool get isCancelledWithinWindow {
    if (!isCancelled) return false;
    final now = DateTime.now();
    final end = endTime ?? startTime.add(const Duration(hours: 2));
    return now.isAfter(startTime) && now.isBefore(end);
  }
}

enum PumpingStatus {
  active,
  paused,
  scheduled,
  completed,
  cancelled,
}

// lib/features/water_feedback/domain/entities/active_schedule_status_entity.dart

class ActiveScheduleStatusEntity {
  const ActiveScheduleStatusEntity({
    required this.hasActiveSchedule,
    required this.alreadySubmittedFeedback,
    this.scheduleId,
    this.schedulePath,
    this.areaName,
    this.startTime,
    this.endTime,
    this.actualEndTime,
    this.unitId,
    this.neighborhoodId,
    this.scheduleStatus = 'ACTIVE',
    this.feedbackWindowHours = 24,
  });

  final bool hasActiveSchedule;
  final int? scheduleId;
  final String? schedulePath;
  final bool alreadySubmittedFeedback;
  final String? areaName;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? actualEndTime;
  final int? unitId;
  final int? neighborhoodId;
  final String scheduleStatus; // 'ACTIVE', 'COMPLETED', 'CANCELLED', etc.
  final int feedbackWindowHours;

  String get timeRemaining {
    if (!hasActiveSchedule || endTime == null) return '';
    final now = DateTime.now();
    final remaining = endTime!.difference(now);
    if (remaining.isNegative) return 'انتهى';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    if (hours > 0) return '$hours ساعة و $minutes دقيقة';
    return '$minutes دقيقة';
  }

  /// Whether feedback can still be submitted for a completed schedule
  /// based on actualEndTime + feedbackWindowHours.
  bool get isWithinFeedbackWindow {
    if (actualEndTime == null) return true;
    final deadline = actualEndTime!.add(Duration(hours: feedbackWindowHours));
    return DateTime.now().isBefore(deadline);
  }

  ActiveScheduleStatusEntity copyWith({
    bool? hasActiveSchedule,
    int? scheduleId,
    String? schedulePath,
    bool? alreadySubmittedFeedback,
    String? areaName,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? actualEndTime,
    int? unitId,
    int? neighborhoodId,
    String? scheduleStatus,
    int? feedbackWindowHours,
  }) {
    return ActiveScheduleStatusEntity(
      hasActiveSchedule: hasActiveSchedule ?? this.hasActiveSchedule,
      scheduleId: scheduleId ?? this.scheduleId,
      schedulePath: schedulePath ?? this.schedulePath,
      alreadySubmittedFeedback:
          alreadySubmittedFeedback ?? this.alreadySubmittedFeedback,
      areaName: areaName ?? this.areaName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      unitId: unitId ?? this.unitId,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
      scheduleStatus: scheduleStatus ?? this.scheduleStatus,
      feedbackWindowHours: feedbackWindowHours ?? this.feedbackWindowHours,
    );
  }
}

// lib/features/water_feedback/data/models/active_schedule_status_model.dart
//
// Serialization layer for [ActiveScheduleStatusEntity]. The domain entity stays
// pure Dart; JSON mapping lives here as an extension.

import 'package:qatrah/features/water_feedback/domain/entities/active_schedule_status_entity.dart';

extension ActiveScheduleStatusMapper on ActiveScheduleStatusEntity {
  static ActiveScheduleStatusEntity fromJson(Map<String, dynamic> json) {
    final scheduleId = _asInt(json['scheduleId'] ?? json['id']);
    final scheduleStatus =
        (json['scheduleStatus'] ?? json['status'] ?? 'ACTIVE')
            .toString()
            .toUpperCase();
    final hasFeedbackCandidate =
        scheduleId != null &&
        (scheduleStatus == 'ACTIVE' || scheduleStatus == 'COMPLETED');

    return ActiveScheduleStatusEntity(
      hasActiveSchedule:
          (json['hasActiveSchedule'] as bool? ?? false) || hasFeedbackCandidate,
      scheduleId: scheduleId,
      schedulePath:
          (json['schedulePath'] ?? json['areaPath'] ?? json['fullLocationPath'])
              as String?,
      alreadySubmittedFeedback:
          json['alreadySubmittedFeedback'] as bool? ??
          json['hasFeedback'] as bool? ??
          false,
      areaName: (json['areaName'] ?? json['targetLocationName']) as String?,
      startTime: _parseDate(json['startTime']),
      endTime: _parseDate(json['endTime']),
      actualEndTime: _parseDate(json['actualEndTime']),
      unitId: _asInt(json['unitId']),
      neighborhoodId: _asInt(json['neighborhoodId']),
      scheduleStatus: scheduleStatus,
      feedbackWindowHours: _asInt(json['feedbackWindowHours']) ?? 24,
    );
  }
}

int? _asInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

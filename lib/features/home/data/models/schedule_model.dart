// lib/features/home/data/models/schedule_model.dart
//
// Serialization layer for [ScheduleEntity]. The domain entity stays pure Dart;
// JSON mapping lives here as an extension.

import 'package:qatrah/features/home/domain/entities/schedule_entity.dart';

extension ScheduleModelMapper on ScheduleEntity {
  static ScheduleEntity fromJson(Map<String, dynamic> json) {
    final startTime = DateTime.parse(json['startTime'] as String);
    final endTimeRaw = (json['actualEndTime'] ?? json['endTime'])?.toString();
    final actualEndTimeRaw = json['actualEndTime']?.toString();

    return ScheduleEntity(
      id: (json['id'] as num).toInt(),
      regionId: (json['regionId'] as num?)?.toInt(),
      unitId: (json['unitId'] as num?)?.toInt(),
      neighborhoodId: (json['neighborhoodId'] as num?)?.toInt(),
      zoneId: (json['zoneId'] as num?)?.toInt(),
      areaName:
          (json['areaName'] ?? json['targetLocationName'] ?? '') as String,
      areaPath: (json['areaPath'] ?? json['fullLocationPath'] ?? '') as String,
      startTime: startTime,
      endTime: endTimeRaw != null ? DateTime.parse(endTimeRaw) : startTime,
      actualEndTime: actualEndTimeRaw != null
          ? DateTime.parse(actualEndTimeRaw)
          : null,
      status: ScheduleStatus.values.firstWhere(
        (e) =>
            e.name.toUpperCase() ==
            (json['status'] as String? ?? '').toUpperCase(),
        orElse: () => ScheduleStatus.scheduled,
      ),
      notes: json['notes'] as String?,
      // Try multiple API field names for the cancellation reason.
      cancelledReason:
          json['cancelledReason'] as String? ??
          json['cancellationReason'] as String? ??
          json['reason'] as String?,
      pauseReason:
          json['pauseReason'] as String? ?? json['pausedReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'regionId': regionId,
      'unitId': unitId,
      'neighborhoodId': neighborhoodId,
      'zoneId': zoneId,
      'areaName': areaName,
      'areaPath': areaPath,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'actualEndTime': actualEndTime?.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'cancelledReason': cancelledReason,
      'pauseReason': pauseReason,
    };
  }
}

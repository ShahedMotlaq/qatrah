// lib/features/employee/data/models/schedule_model.dart
//
// Serialization layer for the employee [ScheduleEntity]. The domain entity
// stays pure Dart; JSON mapping lives here as an extension.

import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';

extension ScheduleModelMapper on ScheduleEntity {
  static ScheduleEntity fromJson(Map<String, dynamic> json) {
    final actualEndTimeRaw = json['actualEndTime']?.toString();
    final parsedStatus = json['status'] as String? ?? 'SCHEDULED';

    return ScheduleEntity(
      id: json['id'] as int? ?? 0,
      regionId: json['regionId'] as int? ?? 0,
      unitId: json['unitId'] as int?,
      neighborhoodId: json['neighborhoodId'] as int?,
      zoneId: json['zoneId'] as int?,
      regionName: json['regionName'] as String? ?? '',
      unitName: json['unitName'] as String?,
      neighborhoodName: json['neighborhoodName'] as String?,
      zoneName: json['zoneName'] as String?,
      fullLocationPath: json['fullLocationPath'] as String? ?? '',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      actualEndTime: actualEndTimeRaw != null
          ? DateTime.parse(actualEndTimeRaw)
          : null,
      status: parsedStatus,
      notes: json['notes'] as String?,
      cancellationReason:
          json['cancellationReason'] as String? ??
          json['cancelledReason'] as String? ??
          json['reason'] as String?,
      pauseReason:
          json['pauseReason'] as String? ?? json['pausedReason'] as String?,
      temporaryFailure:
          json['temporaryFailure'] as bool? ??
          (parsedStatus.toUpperCase() == 'PAUSED'),
    );
  }
}

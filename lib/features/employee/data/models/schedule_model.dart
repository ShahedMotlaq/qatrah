// lib/features/employee/data/models/schedule_model.dart
//
// Serialization layer for the employee [ScheduleEntity]. The domain entity
// stays pure Dart; JSON mapping lives here as an extension.

import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';

/// First non-empty value among [keys].
String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final raw = json[key]?.toString();
    if (raw != null && raw.isNotEmpty) return raw;
  }
  return null;
}

extension ScheduleModelMapper on ScheduleEntity {
  /// Reads a `PumpingRunDto` — the staff-facing row. The older schedule field
  /// names are kept as fallbacks so a cached or legacy payload still parses.
  static ScheduleEntity fromJson(Map<String, dynamic> json) {
    final startRaw = _firstString(json, ['plannedStartAt', 'startTime']);
    final endRaw = _firstString(json, ['plannedEndAt', 'endTime']);
    if (startRaw == null || endRaw == null) {
      throw FormatException('run $json has no planned start/end');
    }
    final actualEndTimeRaw = _firstString(json, [
      'actualEndAt',
      'actualEndTime',
    ]);
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
      startTime: DateTime.parse(startRaw),
      endTime: DateTime.parse(endRaw),
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

// lib/features/home/data/models/pumping_status_model.dart
//
// Serialization layer for [PumpingStatusEntity]. The domain entity stays pure
// Dart; JSON mapping lives here as an extension.

import 'package:qatrah/features/home/domain/entities/pumping_status_entity.dart';

extension PumpingStatusModelMapper on PumpingStatusEntity {
  static PumpingStatusEntity fromJson(Map<String, dynamic> json) {
    // [endTime] is the *planned* window end. We must NOT let an actualEndTime
    // (e.g. a cancellation/stop timestamp) override it, otherwise the window
    // getters (isCancelledWithinWindow / isWithinScheduledTime …) collapse and
    // a still-current cancelled period stops showing. Real completion time is
    // kept separately in [actualEndTime].
    final endTimeRaw = (json['endTime'] ?? json['actualEndTime'])?.toString();
    final actualEndTimeRaw = json['actualEndTime']?.toString();
    final parsedStatus = PumpingStatus.values.firstWhere(
      (e) =>
          e.name.toUpperCase() ==
          (json['status'] as String? ?? '').toUpperCase(),
      orElse: () => PumpingStatus.scheduled,
    );

    return PumpingStatusEntity(
      scheduleId: ((json['scheduleId'] ?? json['id']) as num).toInt(),
      areaName:
          (json['areaName'] ?? json['targetLocationName'] ?? '') as String,
      areaPath: (json['areaPath'] ?? json['fullLocationPath'] ?? '') as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: endTimeRaw != null ? DateTime.parse(endTimeRaw) : null,
      actualEndTime: actualEndTimeRaw != null
          ? DateTime.parse(actualEndTimeRaw)
          : null,
      status: parsedStatus,
      hasFeedback: json['hasFeedback'] as bool? ?? false,
      cancelledReason:
          json['cancelledReason'] as String? ??
          json['cancellationReason'] as String? ??
          json['reason'] as String?,
      pauseReason:
          json['pauseReason'] as String? ?? json['pausedReason'] as String?,
      temporaryFailure:
          json['temporaryFailure'] as bool? ??
          (parsedStatus == PumpingStatus.paused),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheduleId': scheduleId,
      'areaName': areaName,
      'areaPath': areaPath,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'actualEndTime': actualEndTime?.toIso8601String(),
      'status': status.name,
      'hasFeedback': hasFeedback,
      'cancelledReason': cancelledReason,
      'pauseReason': pauseReason,
      'temporaryFailure': temporaryFailure,
    };
  }
}

import 'package:equatable/equatable.dart';

class ScheduleEntity extends Equatable {
  const ScheduleEntity({
    required this.id,
    required this.regionId,
    required this.regionName,
    required this.fullLocationPath,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.unitId,
    this.neighborhoodId,
    this.zoneId,
    this.unitName,
    this.neighborhoodName,
    this.zoneName,
    this.actualEndTime,
    this.notes,
    this.cancellationReason,
    this.pauseReason,
    this.temporaryFailure = false,
  });

  final int id;
  final int regionId;
  final int? unitId;
  final int? neighborhoodId;
  final int? zoneId;
  final String regionName;
  final String? unitName;
  final String? neighborhoodName;
  final String? zoneName;
  final String fullLocationPath;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? actualEndTime;
  final String status;
  final String? notes;
  final String? cancellationReason;

  /// Reason provided by the operator when a schedule is paused.
  /// Mapped from the API fields: `pauseReason`, `pausedReason`. Distinct from
  /// [cancellationReason] which applies to cancelled schedules.
  final String? pauseReason;

  /// Whether the schedule is temporarily stopped (e.g., technical issue).
  /// True when status == 'PAUSED'.
  final bool temporaryFailure;

  @override
  List<Object?> get props => [
    id,
    regionId,
    unitId,
    neighborhoodId,
    zoneId,
    regionName,
    unitName,
    neighborhoodName,
    zoneName,
    fullLocationPath,
    startTime,
    endTime,
    actualEndTime,
    status,
    notes,
    cancellationReason,
    pauseReason,
    temporaryFailure,
  ];

  ScheduleEntity copyWith({
    int? id,
    int? regionId,
    int? unitId,
    int? neighborhoodId,
    int? zoneId,
    String? regionName,
    String? unitName,
    String? neighborhoodName,
    String? zoneName,
    String? fullLocationPath,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? actualEndTime,
    String? status,
    String? notes,
    String? cancellationReason,
    String? pauseReason,
    bool? temporaryFailure,
  }) {
    return ScheduleEntity(
      id: id ?? this.id,
      regionId: regionId ?? this.regionId,
      unitId: unitId ?? this.unitId,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
      zoneId: zoneId ?? this.zoneId,
      regionName: regionName ?? this.regionName,
      unitName: unitName ?? this.unitName,
      neighborhoodName: neighborhoodName ?? this.neighborhoodName,
      zoneName: zoneName ?? this.zoneName,
      fullLocationPath: fullLocationPath ?? this.fullLocationPath,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      pauseReason: pauseReason ?? this.pauseReason,
      temporaryFailure: temporaryFailure ?? this.temporaryFailure,
    );
  }
}

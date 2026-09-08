import 'package:equatable/equatable.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {}

class FilterRegionChanged extends DashboardEvent {
  const FilterRegionChanged(this.region);
  final LocationLookupEntity? region;
}

class FilterUnitChanged extends DashboardEvent {
  const FilterUnitChanged(this.unit);
  final LocationLookupEntity? unit;
}

class FilterNeighborhoodChanged extends DashboardEvent {
  const FilterNeighborhoodChanged(this.neighborhood);
  final LocationLookupEntity? neighborhood;
}

class FilterZoneChanged extends DashboardEvent {
  const FilterZoneChanged(this.zone);
  final LocationLookupEntity? zone;
}

class FilterStatusChanged extends DashboardEvent {
  const FilterStatusChanged(this.status);
  final String? status;
}

class FilterFromDateChanged extends DashboardEvent {
  const FilterFromDateChanged(this.date);
  final DateTime? date;
}

class FilterToDateChanged extends DashboardEvent {
  const FilterToDateChanged(this.date);
  final DateTime? date;
}

class ResetFilters extends DashboardEvent {}

class StartScheduleEvent extends DashboardEvent {
  const StartScheduleEvent(this.id);
  final int id;
}

class EndScheduleEvent extends DashboardEvent {
  const EndScheduleEvent(this.id);
  final int id;
}

class PauseScheduleEvent extends DashboardEvent {
  const PauseScheduleEvent(this.id, {this.pauseReason});
  final int id;
  final String? pauseReason;

  @override
  List<Object?> get props => [id, pauseReason];
}

class ResumeScheduleEvent extends DashboardEvent {
  const ResumeScheduleEvent(this.id);
  final int id;
}

class CancelScheduleEvent extends DashboardEvent {
  const CancelScheduleEvent(this.id, {this.cancellationReason});
  final int id;
  final String? cancellationReason;

  @override
  List<Object?> get props => [id, cancellationReason];
}

/// Delay the entire persistent schedule by [hours] hours.
class ShiftScheduleEvent extends DashboardEvent {
  const ShiftScheduleEvent(this.id, {required this.hours});
  final int id;
  final int hours;

  @override
  List<Object?> get props => [id, hours];
}

class CreateScheduleSubmitted extends DashboardEvent {
  const CreateScheduleSubmitted({
    required this.regionId,
    required this.start,
    required this.end,
    this.unitId,
    this.neighborhoodId,
    this.zoneId,
    this.notes,
  });
  final int regionId;
  final int? unitId;
  final int? neighborhoodId;
  final int? zoneId;
  final DateTime start;
  final DateTime end;
  final String? notes;
}

class FetchUnitsEvent extends DashboardEvent {
  const FetchUnitsEvent(this.regionId);
  final int regionId;
}

class FetchNeighborhoodsEvent extends DashboardEvent {
  const FetchNeighborhoodsEvent(this.regionId);
  final int regionId;
}

class FetchZonesEvent extends DashboardEvent {
  const FetchZonesEvent(this.regionId);
  final int regionId;
}

class ResetHierarchyEvent extends DashboardEvent {}

class RefreshSchedulesEvent extends DashboardEvent {}

class PushNotificationReceivedEvent extends DashboardEvent {
  const PushNotificationReceivedEvent({
    required this.type,
    this.scheduleId,
  });
  final String type;
  final int? scheduleId;
}

class UpdateScheduleSubmitted extends DashboardEvent {
  const UpdateScheduleSubmitted({
    required this.scheduleId,
    required this.regionId,
    required this.start,
    required this.end,
    this.unitId,
    this.neighborhoodId,
    this.zoneId,
    this.notes,
  });
  final int scheduleId;
  final int regionId;
  final int? unitId;
  final int? neighborhoodId;
  final int? zoneId;
  final DateTime start;
  final DateTime end;
  final String? notes;

  @override
  List<Object?> get props => [
    scheduleId,
    regionId,
    unitId,
    neighborhoodId,
    zoneId,
    start,
    end,
    notes,
  ];
}

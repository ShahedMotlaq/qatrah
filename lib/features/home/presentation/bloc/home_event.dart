import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {}

/// Explicit user-initiated refresh (e.g. pull-to-refresh).
class RefreshHomeDataEvent extends HomeEvent {}

/// Automatic background refresh triggered when the user switches back
/// to the Home tab. The UI shows a small animated icon instead of the
/// full-page shimmer.
class SilentRefreshHomeDataEvent extends HomeEvent {}

class ToggleAreaSelectionEvent extends HomeEvent {}

class ToggleAreaWatchEvent extends HomeEvent {
  const ToggleAreaWatchEvent({required this.areaId, required this.watch});
  final int areaId;
  final bool watch;

  @override
  List<Object?> get props => [areaId, watch];
}

/// Dispatched when the user taps an area card in the expanded dropdown.
/// Updates the display location so pump status reflects the selected area.
class SelectDisplayAreaEvent extends HomeEvent {
  const SelectDisplayAreaEvent(this.areaId);
  final int areaId;

  @override
  List<Object?> get props => [areaId];
}

class LoadMoreSchedulesEvent extends HomeEvent {}

class ToggleAreaItemEvent extends HomeEvent {
  const ToggleAreaItemEvent(this.areaName);
  final String areaName;

  @override
  List<Object?> get props => [areaName];
}

class UpdateWatchedLocationEvent extends HomeEvent {
  const UpdateWatchedLocationEvent({
    this.neighborhoodId,
    this.zoneId,
    this.locationName,
  });
  final int? neighborhoodId;
  final int? zoneId;
  final String? locationName;

  @override
  List<Object?> get props => [neighborhoodId, zoneId, locationName];
}

class FetchRegionsEvent extends HomeEvent {}

class SelectRegionEvent extends HomeEvent {
  const SelectRegionEvent(this.regionId);
  final int regionId;

  @override
  List<Object?> get props => [regionId];
}

class SelectUnitEvent extends HomeEvent {
  const SelectUnitEvent(this.unitId);
  final int unitId;

  @override
  List<Object?> get props => [unitId];
}

class SelectNeighborhoodEvent extends HomeEvent {
  const SelectNeighborhoodEvent(this.neighborhoodId);
  final int neighborhoodId;

  @override
  List<Object?> get props => [neighborhoodId];
}

class SelectZoneEvent extends HomeEvent {
  const SelectZoneEvent(this.zoneId);
  final int zoneId;

  @override
  List<Object?> get props => [zoneId];
}

class NavigateFromNotificationEvent extends HomeEvent {
  const NavigateFromNotificationEvent({
    this.scheduleId,
    this.regionName,
    this.unitName,
    this.neighborhoodName,
    this.zoneName,
  });
  final int? scheduleId;
  final String? regionName;
  final String? unitName;
  final String? neighborhoodName;
  final String? zoneName;

  @override
  List<Object?> get props => [
    scheduleId,
    regionName,
    unitName,
    neighborhoodName,
    zoneName,
  ];
}

class RefreshProfileDefaultLocationEvent extends HomeEvent {}

class ToggleGlobalLocationModeEvent extends HomeEvent {
  const ToggleGlobalLocationModeEvent(this.enabled);
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

/// Clears the selected monitored area and reverts to the profile default location.
class ClearMonitoredAreaSelectionEvent extends HomeEvent {}

// Legacy no-op events kept for compatibility with HomeBloc internals.
class ShowPumpingOverlayEvent extends HomeEvent {}

class DismissPumpingOverlayEvent extends HomeEvent {}

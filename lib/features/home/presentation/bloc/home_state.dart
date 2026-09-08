import 'package:equatable/equatable.dart';
import 'package:qatrah/features/auth/domain/entities/user_entity.dart';
import 'package:qatrah/features/home/domain/entities/area_entity.dart';
import 'package:qatrah/features/home/domain/entities/pumping_status_entity.dart';
import 'package:qatrah/features/home/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

// ──────────────────────────────────────────────────────────────────────
/// Describes what the "Current Status" card section should render.
///
/// Derived entirely from [HomeState.pumpingStatus] — never stored separately.
///
/// ```
/// switch (state.pumpingDisplayMode) {
///   case PumpingDisplayMode.live                 → show live-pumping card with countdown
///   case PumpingDisplayMode.cancelledWithinPeriod → show "cancelled for this period" message
///   case PumpingDisplayMode.lastSession          → show last-completed card + time-ago
///   case PumpingDisplayMode.empty                → show empty-state placeholder
/// }
/// ```
// ──────────────────────────────────────────────────────────────────────
enum PumpingDisplayMode { live, cancelledWithinPeriod, lastSession, empty }

class HomeState extends Equatable {
  const HomeState({
    this.isFirstLoad = true,
    this.isLoading = true,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isAreaSelectionExpanded = false,
    this.user,
    this.watchedAreas = const [],
    this.monitoredAreas = const [],
    this.pumpingStatus = const [],
    this.schedules = const [],
    this.schedulesPage = 0,
    this.hasMoreSchedules = true,
    this.errorMessage,
    this.filteredNeighborhoodId,
    this.filteredZoneId,
    this.filteredLocationName,
    this.regions = const [],
    this.units = const [],
    this.neighborhoods = const [],
    this.zones = const [],
    this.selectedUnitIds = const [],
    this.selectedZoneIds = const [],
    this.selectedRegionId,
    this.selectedUnitId,
    this.selectedNeighborhoodId,
    this.selectedZoneId,
    this.isRegionsLoading = false,
    this.isUnitsLoading = false,
    this.isNeighborhoodsLoading = false,
    this.isZonesLoading = false,
    this.showPumpingOverlay = false,
    this.hasShownPumpingOverlay = false,
    this.isGlobalLocationMode = false,
    this.selectedMonitoredArea,
  });
  final bool isFirstLoad;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isAreaSelectionExpanded;
  final UserEntity? user;

  final List<AreaEntity> watchedAreas;
  final List<AreaEntity> monitoredAreas;
  final List<PumpingStatusEntity> pumpingStatus;
  final List<ScheduleEntity> schedules;
  final int schedulesPage;
  final bool hasMoreSchedules;
  final String? errorMessage;

  final int? filteredNeighborhoodId;
  final int? filteredZoneId;
  final String? filteredLocationName;

  final List<LocationLookupEntity> regions;
  final List<LocationLookupEntity> units;
  final List<LocationLookupEntity> neighborhoods;
  final List<LocationLookupEntity> zones;

  final List<int> selectedUnitIds;
  final List<int> selectedZoneIds;

  final int? selectedRegionId;
  final int? selectedUnitId;
  final int? selectedNeighborhoodId;
  final int? selectedZoneId;

  final bool isRegionsLoading;
  final bool isUnitsLoading;
  final bool isNeighborhoodsLoading;
  final bool isZonesLoading;
  final bool showPumpingOverlay;
  final bool hasShownPumpingOverlay;
  final bool isGlobalLocationMode;

  /// The monitored area the user has explicitly tapped to view its data.
  /// Null means show the profile's default location.
  /// Not persisted — resets to null on app restart.
  final AreaEntity? selectedMonitoredArea;

  // ── Computed display selectors ───────────────────────────────────────────
  // These are derived from [pumpingStatus] and are NOT stored in [props] since
  // they add no independent state — they always reflect the list contents.

  /// The active session (clock is between startTime and endTime), if any.
  PumpingStatusEntity? get activeSession => pumpingStatus
      .where((s) => s.isActive)
      .toList()
      .fold<PumpingStatusEntity?>(
        null,
        (prev, s) =>
            prev == null || s.startTime.isBefore(prev.startTime) ? s : prev,
      );

  /// A paused session — still within its time window but temporarily stopped.
  PumpingStatusEntity? get pausedSession => pumpingStatus
      .where((s) => s.isPaused)
      .toList()
      .fold<PumpingStatusEntity?>(
        null,
        (prev, s) =>
            prev == null || s.startTime.isBefore(prev.startTime) ? s : prev,
      );

  /// The highest-priority live session: ACTIVE takes precedence over PAUSED.
  /// Used for Priority #1 in [pumpingDisplayMode].
  PumpingStatusEntity? get liveSession => activeSession ?? pausedSession;

  /// A scheduled session currently within the scheduled time window (available for cancellation).
  PumpingStatusEntity? get scheduledWithinTimeSession => pumpingStatus
      .where((s) => s.isWithinScheduledTime)
      .toList()
      .fold<PumpingStatusEntity?>(
        null,
        (prev, s) =>
            prev == null || s.startTime.isBefore(prev.startTime) ? s : prev,
      );

  /// The most recently cancelled session (within the last 48 hours).
  PumpingStatusEntity? get cancelledSession => pumpingStatus
      .where((s) => s.isCancelled)
      .toList()
      .fold<PumpingStatusEntity?>(
        null,
        (prev, s) =>
            prev == null || s.startTime.isAfter(prev.startTime) ? s : prev,
      );

  /// A cancelled session currently within its scheduled time window.
  PumpingStatusEntity? get cancelledWithinWindow => pumpingStatus
      .where((s) => s.isCancelledWithinWindow)
      .toList()
      .fold<PumpingStatusEntity?>(
        null,
        (prev, s) =>
            prev == null || s.startTime.isAfter(prev.startTime) ? s : prev,
      );

  /// The most recently completed session — used for the "Last Session" card.
  /// Only items with a non-null [actualEndTime] are considered to avoid
  /// showing schedules with empty or planned-only times.
  PumpingStatusEntity? get lastCompletedSession => pumpingStatus
      .where(
        (s) => s.isCompleted && s.actualEndTime != null,
      )
      .toList()
      .fold<PumpingStatusEntity?>(
        null,
        (prev, s) {
          final sEnd = s.actualEndTime!;
          final prevEnd = prev?.actualEndTime;
          return prevEnd == null || sEnd.isAfter(prevEnd) ? s : prev;
        },
      );

  /// A scheduled session whose time window has passed but was never
  /// marked COMPLETED. Kept as a getter for data-layer completeness
  /// but intentionally excluded from [pumpingDisplayMode] so it is
  /// never shown as "Last Pumping Ended".
  PumpingStatusEntity? get completedScheduledSession => pumpingStatus
      .where((s) => s.isScheduledPastTime)
      .toList()
      .fold<PumpingStatusEntity?>(
        null,
        (prev, s) {
          final sEnd = s.endTime ?? s.startTime;
          final prevEnd = prev?.endTime ?? prev?.startTime;
          return prevEnd == null || sEnd.isAfter(prevEnd) ? s : prev;
        },
      );

  /// The closest upcoming SCHEDULED session (earliest startTime in the future).
  /// Kept for upcoming-schedule data, not for the current-status card.
  PumpingStatusEntity? get nextScheduled => pumpingStatus
      .where((s) => s.isScheduled && DateTime.now().isBefore(s.startTime))
      .toList()
      .fold<PumpingStatusEntity?>(
        null,
        (prev, s) =>
            prev == null || s.startTime.isBefore(prev.startTime) ? s : prev,
      );

  /// What the "Current Pumping Status" section should render.
  ///
  /// Priority:
  /// 1. ACTIVE or PAUSED (live now / temporarily stopped)
  /// 2. CANCELLED within time window (cancelled for this period)
  /// 3. COMPLETED (last session ended)
  /// 4. Empty (no current or completed pumping)
  PumpingDisplayMode get pumpingDisplayMode {
    if (liveSession != null) return PumpingDisplayMode.live;
    if (cancelledWithinWindow != null)
      return PumpingDisplayMode.cancelledWithinPeriod;
    // Only truly COMPLETED schedules are shown as "Last Pumping Ended".
    // A SCHEDULED item whose time passed but was never completed
    // must NOT be treated as a completed session.
    if (lastCompletedSession != null) return PumpingDisplayMode.lastSession;
    return PumpingDisplayMode.empty;
  }

  bool get hasWatchedAreas => monitoredAreas.isNotEmpty;

  /// Convenience getter used by the water-physics overlay check.
  bool get hasActivePumping => liveSession != null;

  bool get hasSchedules => schedules.isNotEmpty;

  HomeState copyWith({
    bool? isFirstLoad,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isAreaSelectionExpanded,
    UserEntity? user,
    List<AreaEntity>? watchedAreas,
    List<AreaEntity>? monitoredAreas,
    List<PumpingStatusEntity>? pumpingStatus,
    List<ScheduleEntity>? schedules,
    int? schedulesPage,
    bool? hasMoreSchedules,
    String? errorMessage,
    int? filteredNeighborhoodId,
    int? filteredZoneId,
    String? filteredLocationName,
    List<LocationLookupEntity>? regions,
    List<LocationLookupEntity>? units,
    List<LocationLookupEntity>? neighborhoods,
    List<LocationLookupEntity>? zones,
    List<int>? selectedUnitIds,
    List<int>? selectedZoneIds,
    int? selectedRegionId,
    int? selectedUnitId,
    int? selectedNeighborhoodId,
    int? selectedZoneId,
    bool? isRegionsLoading,
    bool? isUnitsLoading,
    bool? isNeighborhoodsLoading,
    bool? isZonesLoading,
    bool? showPumpingOverlay,
    bool? hasShownPumpingOverlay,
    bool? isGlobalLocationMode,
    AreaEntity? selectedMonitoredArea,
    bool clearError = false,
    bool clearFilter = false,
    bool clearSelectedMonitoredArea = false,
    bool resetUnits = false,
    bool resetNeighborhoods = false,
    bool resetZones = false,
  }) {
    return HomeState(
      isFirstLoad: isFirstLoad ?? this.isFirstLoad,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isAreaSelectionExpanded:
          isAreaSelectionExpanded ?? this.isAreaSelectionExpanded,
      user: user ?? this.user,
      watchedAreas: watchedAreas ?? this.watchedAreas,
      monitoredAreas: monitoredAreas ?? this.monitoredAreas,
      pumpingStatus: pumpingStatus ?? this.pumpingStatus,
      schedules: schedules ?? this.schedules,
      schedulesPage: schedulesPage ?? this.schedulesPage,
      hasMoreSchedules: hasMoreSchedules ?? this.hasMoreSchedules,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filteredNeighborhoodId: clearFilter
          ? null
          : (filteredNeighborhoodId ?? this.filteredNeighborhoodId),
      filteredZoneId: clearFilter
          ? null
          : (filteredZoneId ?? this.filteredZoneId),
      filteredLocationName: clearFilter
          ? null
          : (filteredLocationName ?? this.filteredLocationName),
      regions: regions ?? this.regions,
      units: resetUnits ? const [] : (units ?? this.units),
      neighborhoods: (resetUnits || resetNeighborhoods)
          ? const []
          : (neighborhoods ?? this.neighborhoods),
      zones: (resetUnits || resetNeighborhoods || resetZones)
          ? const []
          : (zones ?? this.zones),
      selectedUnitIds: selectedUnitIds ?? this.selectedUnitIds,
      selectedZoneIds: selectedZoneIds ?? this.selectedZoneIds,
      selectedRegionId: selectedRegionId ?? this.selectedRegionId,
      selectedUnitId: resetUnits
          ? null
          : (selectedUnitId ?? this.selectedUnitId),
      selectedNeighborhoodId: (resetUnits || resetNeighborhoods)
          ? null
          : (selectedNeighborhoodId ?? this.selectedNeighborhoodId),
      selectedZoneId: (resetUnits || resetNeighborhoods || resetZones)
          ? null
          : (selectedZoneId ?? this.selectedZoneId),
      isRegionsLoading: isRegionsLoading ?? this.isRegionsLoading,
      isUnitsLoading: isUnitsLoading ?? this.isUnitsLoading,
      isNeighborhoodsLoading:
          isNeighborhoodsLoading ?? this.isNeighborhoodsLoading,
      isZonesLoading: isZonesLoading ?? this.isZonesLoading,
      showPumpingOverlay: showPumpingOverlay ?? this.showPumpingOverlay,
      hasShownPumpingOverlay:
          hasShownPumpingOverlay ?? this.hasShownPumpingOverlay,
      isGlobalLocationMode: isGlobalLocationMode ?? this.isGlobalLocationMode,
      selectedMonitoredArea: clearSelectedMonitoredArea
          ? null
          : (selectedMonitoredArea ?? this.selectedMonitoredArea),
    );
  }

  @override
  List<Object?> get props => [
    isFirstLoad,
    isLoading,
    isRefreshing,
    isLoadingMore,
    isAreaSelectionExpanded,
    user,
    watchedAreas,
    monitoredAreas,
    pumpingStatus,
    schedules,
    schedulesPage,
    hasMoreSchedules,
    errorMessage,
    filteredNeighborhoodId,
    filteredZoneId,
    filteredLocationName,
    regions,
    units,
    neighborhoods,
    zones,
    selectedUnitIds,
    selectedZoneIds,
    selectedRegionId,
    selectedUnitId,
    selectedNeighborhoodId,
    selectedZoneId,
    isRegionsLoading,
    isUnitsLoading,
    isNeighborhoodsLoading,
    isZonesLoading,
    showPumpingOverlay,
    hasShownPumpingOverlay,
    isGlobalLocationMode,
    selectedMonitoredArea,
  ];
}

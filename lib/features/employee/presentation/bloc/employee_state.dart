import 'package:equatable/equatable.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.isLoading = false,
    this.allSchedules = const [],
    this.filteredSchedules = const [],
    this.regions = const [],
    this.units = const [],
    this.neighborhoods = const [],
    this.zones = const [],
    this.isUnitsLoading = false,
    this.isNeighborhoodsLoading = false,
    this.isZonesLoading = false,
    this.filterUnits = const [],
    this.filterNeighborhoods = const [],
    this.filterZones = const [],
    this.isFilterUnitsLoading = false,
    this.isFilterNeighborhoodsLoading = false,
    this.isFilterZonesLoading = false,
    this.isSuccess = false,
    this.selectedRegion,
    this.selectedUnit,
    this.selectedNeighborhood,
    this.selectedZone,
    this.selectedStatus,
    this.fromDate,
    this.toDate,
    this.searchQuery = '',
    this.errorMessage,
  });
  final bool isLoading;
  final List<ScheduleEntity> allSchedules;
  final List<ScheduleEntity> filteredSchedules;

  // For Create Dialog
  final List<LocationLookupEntity> regions;
  final List<LocationLookupEntity> units;
  final List<LocationLookupEntity> neighborhoods;
  final List<LocationLookupEntity> zones;
  final bool isUnitsLoading;
  final bool isNeighborhoodsLoading;
  final bool isZonesLoading;

  // For Dashboard Filters
  final List<LocationLookupEntity> filterUnits;
  final List<LocationLookupEntity> filterNeighborhoods;
  final List<LocationLookupEntity> filterZones;
  final bool isFilterUnitsLoading;
  final bool isFilterNeighborhoodsLoading;
  final bool isFilterZonesLoading;

  final bool isSuccess;

  // Selected Filters
  final LocationLookupEntity? selectedRegion;
  final LocationLookupEntity? selectedUnit;
  final LocationLookupEntity? selectedNeighborhood;
  final LocationLookupEntity? selectedZone;
  final String? selectedStatus;
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Free-text filter matched against notes, reasons and location names.
  final String searchQuery;

  final String? errorMessage;

  /// Filters the operator can see and clear, used to label the filter panel.
  int get activeFilterCount => [
    selectedRegion,
    selectedUnit,
    selectedNeighborhood,
    selectedZone,
    if (selectedStatus != 'ALL') selectedStatus,
    fromDate,
    toDate,
    if (searchQuery.isNotEmpty) searchQuery,
  ].nonNulls.length;

  DashboardState copyWith({
    bool? isLoading,
    List<ScheduleEntity>? allSchedules,
    List<ScheduleEntity>? filteredSchedules,
    List<LocationLookupEntity>? regions,
    List<LocationLookupEntity>? units,
    List<LocationLookupEntity>? neighborhoods,
    List<LocationLookupEntity>? zones,
    bool? isUnitsLoading,
    bool? isNeighborhoodsLoading,
    bool? isZonesLoading,
    List<LocationLookupEntity>? filterUnits,
    List<LocationLookupEntity>? filterNeighborhoods,
    List<LocationLookupEntity>? filterZones,
    bool? isFilterUnitsLoading,
    bool? isFilterNeighborhoodsLoading,
    bool? isFilterZonesLoading,
    bool? isSuccess,
    LocationLookupEntity? selectedRegion,
    LocationLookupEntity? selectedUnit,
    LocationLookupEntity? selectedNeighborhood,
    LocationLookupEntity? selectedZone,
    String? selectedStatus,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
    String? errorMessage,
    bool clearFilters = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      allSchedules: allSchedules ?? this.allSchedules,
      filteredSchedules: filteredSchedules ?? this.filteredSchedules,
      regions: regions ?? this.regions,
      units: units ?? this.units,
      neighborhoods: neighborhoods ?? this.neighborhoods,
      zones: zones ?? this.zones,
      isUnitsLoading: isUnitsLoading ?? this.isUnitsLoading,
      isNeighborhoodsLoading:
          isNeighborhoodsLoading ?? this.isNeighborhoodsLoading,
      isZonesLoading: isZonesLoading ?? this.isZonesLoading,
      filterUnits: clearFilters ? const [] : (filterUnits ?? this.filterUnits),
      filterNeighborhoods: clearFilters
          ? const []
          : (filterNeighborhoods ?? this.filterNeighborhoods),
      filterZones: clearFilters ? const [] : (filterZones ?? this.filterZones),
      isFilterUnitsLoading: isFilterUnitsLoading ?? this.isFilterUnitsLoading,
      isFilterNeighborhoodsLoading:
          isFilterNeighborhoodsLoading ?? this.isFilterNeighborhoodsLoading,
      isFilterZonesLoading: isFilterZonesLoading ?? this.isFilterZonesLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      selectedRegion: clearFilters
          ? null
          : (selectedRegion ?? this.selectedRegion),
      selectedUnit: clearFilters ? null : (selectedUnit ?? this.selectedUnit),
      selectedNeighborhood: clearFilters
          ? null
          : (selectedNeighborhood ?? this.selectedNeighborhood),
      selectedZone: clearFilters ? null : (selectedZone ?? this.selectedZone),
      selectedStatus: clearFilters
          ? null
          : (selectedStatus ?? this.selectedStatus),
      fromDate: clearFilters ? null : (fromDate ?? this.fromDate),
      toDate: clearFilters ? null : (toDate ?? this.toDate),
      searchQuery: clearFilters ? '' : (searchQuery ?? this.searchQuery),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    allSchedules,
    filteredSchedules,
    regions,
    units,
    neighborhoods,
    zones,
    isUnitsLoading,
    isNeighborhoodsLoading,
    isZonesLoading,
    filterUnits,
    filterNeighborhoods,
    filterZones,
    isFilterUnitsLoading,
    isFilterNeighborhoodsLoading,
    isFilterZonesLoading,
    isSuccess,
    selectedRegion,
    selectedUnit,
    selectedNeighborhood,
    selectedZone,
    selectedStatus,
    fromDate,
    toDate,
    searchQuery,
    errorMessage,
  ];
}

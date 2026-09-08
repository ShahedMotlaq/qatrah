// lib/features/profile/presentation/bloc/profile_state.dart

import 'package:equatable/equatable.dart';
import 'package:qatrah/features/auth/domain/entities/user_entity.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

class EditProfileState extends Equatable {
  const EditProfileState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.user,
    this.regions = const [],
    this.units = const [],
    this.neighborhoods = const [],
    this.zones = const [],
    this.isRegionsLoading = false,
    this.isUnitsLoading = false,
    this.isNeighborhoodsLoading = false,
    this.isZonesLoading = false,
    this.fullName = '',
    this.selectedRegion,
    this.selectedUnit,
    this.selectedNeighborhood,
    this.selectedZone,
    this.selectedRegionId,
    this.selectedUnitId,
    this.selectedNeighborhoodId,
    this.selectedZoneId,
    this.defaultRegion,
    this.defaultUnit,
    this.defaultNeighborhood,
    this.defaultZone,
    this.watchedRegion,
    this.watchedUnit,
    this.watchedNeighborhood,
    this.watchedZone,
    this.shouldNavigateToNavbar = false,
  });
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final UserEntity? user;

  // Hierarchy data
  final List<LocationLookupEntity> regions;
  final List<LocationLookupEntity> units;
  final List<LocationLookupEntity> neighborhoods;
  final List<LocationLookupEntity> zones;

  // Loading states for hierarchy
  final bool isRegionsLoading;
  final bool isUnitsLoading;
  final bool isNeighborhoodsLoading;
  final bool isZonesLoading;

  // Form data
  final String fullName;
  final LocationLookupEntity? selectedRegion;
  final LocationLookupEntity? selectedUnit;
  final LocationLookupEntity? selectedNeighborhood;
  final LocationLookupEntity? selectedZone;

  final int? selectedRegionId;
  final int? selectedUnitId;
  final int? selectedNeighborhoodId;
  final int? selectedZoneId;

  final LocationLookupEntity? defaultRegion;
  final LocationLookupEntity? defaultUnit;
  final LocationLookupEntity? defaultNeighborhood;
  final LocationLookupEntity? defaultZone;
  final LocationLookupEntity? watchedRegion;
  final LocationLookupEntity? watchedUnit;
  final LocationLookupEntity? watchedNeighborhood;
  final LocationLookupEntity? watchedZone;

  final bool shouldNavigateToNavbar;

  EditProfileState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    UserEntity? user,
    List<LocationLookupEntity>? regions,
    List<LocationLookupEntity>? units,
    List<LocationLookupEntity>? neighborhoods,
    List<LocationLookupEntity>? zones,
    bool? isRegionsLoading,
    bool? isUnitsLoading,
    bool? isNeighborhoodsLoading,
    bool? isZonesLoading,
    String? fullName,
    LocationLookupEntity? selectedRegion,
    LocationLookupEntity? selectedUnit,
    LocationLookupEntity? selectedNeighborhood,
    LocationLookupEntity? selectedZone,
    int? selectedRegionId,
    int? selectedUnitId,
    int? selectedNeighborhoodId,
    int? selectedZoneId,
    LocationLookupEntity? defaultRegion,
    LocationLookupEntity? defaultUnit,
    LocationLookupEntity? defaultNeighborhood,
    LocationLookupEntity? defaultZone,
    LocationLookupEntity? watchedRegion,
    LocationLookupEntity? watchedUnit,
    LocationLookupEntity? watchedNeighborhood,
    LocationLookupEntity? watchedZone,
    bool? shouldNavigateToNavbar,
    bool clearError = false,
    bool clearSuccess = false,
    bool resetUnits = false,
    bool resetNeighborhoods = false,
    bool resetZones = false,
    bool resetLocationSelection = false,
    bool clearDefaultLocation = false,
    bool clearWatchedLocation = false,
  }) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: !clearSuccess && (isSuccess ?? this.isSuccess),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: user ?? this.user,
      regions: regions ?? this.regions,
      units: (resetLocationSelection || resetUnits)
          ? const []
          : (units ?? this.units),
      neighborhoods: (resetLocationSelection || resetNeighborhoods)
          ? const []
          : (neighborhoods ?? this.neighborhoods),
      zones: (resetLocationSelection || resetZones)
          ? const []
          : (zones ?? this.zones),
      isRegionsLoading: isRegionsLoading ?? this.isRegionsLoading,
      isUnitsLoading: isUnitsLoading ?? this.isUnitsLoading,
      isNeighborhoodsLoading:
          isNeighborhoodsLoading ?? this.isNeighborhoodsLoading,
      isZonesLoading: isZonesLoading ?? this.isZonesLoading,
      fullName: fullName ?? this.fullName,
      selectedRegion: resetLocationSelection
          ? null
          : (selectedRegion ?? this.selectedRegion),
      selectedUnit: (resetLocationSelection || resetUnits)
          ? null
          : (selectedUnit ?? this.selectedUnit),
      selectedNeighborhood: (resetLocationSelection || resetNeighborhoods)
          ? null
          : (selectedNeighborhood ?? this.selectedNeighborhood),
      selectedZone: (resetLocationSelection || resetZones)
          ? null
          : (selectedZone ?? this.selectedZone),
      selectedRegionId: resetLocationSelection
          ? null
          : (selectedRegionId ?? this.selectedRegionId),
      selectedUnitId: (resetLocationSelection || resetUnits)
          ? null
          : (selectedUnitId ?? this.selectedUnitId),
      selectedNeighborhoodId: (resetLocationSelection || resetNeighborhoods)
          ? null
          : (selectedNeighborhoodId ?? this.selectedNeighborhoodId),
      selectedZoneId: (resetLocationSelection || resetZones)
          ? null
          : (selectedZoneId ?? this.selectedZoneId),
      defaultRegion: clearDefaultLocation
          ? defaultRegion
          : (defaultRegion ?? this.defaultRegion),
      defaultUnit: clearDefaultLocation
          ? defaultUnit
          : (defaultUnit ?? this.defaultUnit),
      defaultNeighborhood: clearDefaultLocation
          ? defaultNeighborhood
          : (defaultNeighborhood ?? this.defaultNeighborhood),
      defaultZone: clearDefaultLocation
          ? defaultZone
          : (defaultZone ?? this.defaultZone),
      watchedRegion: clearWatchedLocation
          ? watchedRegion
          : (watchedRegion ?? this.watchedRegion),
      watchedUnit: clearWatchedLocation
          ? watchedUnit
          : (watchedUnit ?? this.watchedUnit),
      watchedNeighborhood: clearWatchedLocation
          ? watchedNeighborhood
          : (watchedNeighborhood ?? this.watchedNeighborhood),
      watchedZone: clearWatchedLocation
          ? watchedZone
          : (watchedZone ?? this.watchedZone),
      shouldNavigateToNavbar:
          shouldNavigateToNavbar ?? this.shouldNavigateToNavbar,
    );
  }

  bool get isEmployee => user?.isEmployee ?? false;
  bool get isCitizen => user?.isCitizen ?? false;
  bool get hasDefaultLocation =>
      _hasLocationName(defaultRegion) ||
      _hasLocationName(defaultUnit) ||
      _hasLocationName(defaultNeighborhood) ||
      _hasLocationName(defaultZone);
  bool get hasWatchedLocation =>
      _hasLocationName(watchedRegion) ||
      _hasLocationName(watchedUnit) ||
      _hasLocationName(watchedNeighborhood) ||
      _hasLocationName(watchedZone);

  static bool _hasLocationName(LocationLookupEntity? location) {
    return location?.name.trim().isNotEmpty ?? false;
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSuccess,
    errorMessage,
    user,
    regions,
    units,
    neighborhoods,
    zones,
    isRegionsLoading,
    isUnitsLoading,
    isNeighborhoodsLoading,
    isZonesLoading,
    fullName,
    selectedRegion,
    selectedUnit,
    selectedNeighborhood,
    selectedZone,
    selectedRegionId,
    selectedUnitId,
    selectedNeighborhoodId,
    selectedZoneId,
    defaultRegion,
    defaultUnit,
    defaultNeighborhood,
    defaultZone,
    watchedRegion,
    watchedUnit,
    watchedNeighborhood,
    watchedZone,
    shouldNavigateToNavbar,
  ];
}

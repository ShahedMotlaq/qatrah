// lib/features/home/presentation/bloc/home_bloc.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:qatrah/core/events/profile_event_bus.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/notification/notification_service.dart';
import 'package:qatrah/core/utils/app_logger.dart';
import 'package:qatrah/features/auth/domain/entities/user_entity.dart';
import 'package:qatrah/features/home/domain/usecases/get_pumping_status_usecase.dart';
import 'package:qatrah/features/home/domain/usecases/get_upcoming_schedules_usecase.dart';
import 'package:qatrah/features/home/domain/usecases/get_watched_areas_usecase.dart';
import 'package:qatrah/features/home/domain/usecases/toggle_area_selection_usecase.dart';
import 'package:qatrah/features/home/presentation/bloc/home_event.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart';
import 'package:qatrah/features/home/presentation/bloc/selected_home_address.dart';
import 'package:qatrah/features/profile/domain/repositories/i_hierarchy_repository.dart';
import 'package:qatrah/features/profile/domain/repositories/i_profile_repository.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required GetWatchedAreasUseCase getWatchedAreas,
    required GetPumpingStatusUseCase getPumpingStatus,
    required GetUpcomingSchedulesUseCase getUpcomingSchedules,
    required ToggleAreaWatchUseCase toggleAreaWatch,
    required IHierarchyRepository hierarchyRepository,
    required IProfileRepository profileRepository,
    required SecureStorage secureStorage,
  }) : _getWatchedAreas = getWatchedAreas,
       _getPumpingStatus = getPumpingStatus,
       _getUpcomingSchedules = getUpcomingSchedules,
       _toggleAreaWatch = toggleAreaWatch,
       _hierarchyRepository = hierarchyRepository,
       _profileRepository = profileRepository,
       _secureStorage = secureStorage,
       super(const HomeState()) {
    // Subscribe to profile updates from other screens
    _profileSubscription = ProfileEventBus.instance.onProfileUpdated.listen(
      (_) => add(RefreshProfileDefaultLocationEvent()),
    );

    // Refresh pumping data on any cancellation/status-change push notification
    _notificationSubscription = NotificationService.instance.notificationStream
        .listen(
          _onPushNotification,
        );

    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<RefreshHomeDataEvent>(_onRefreshHomeData);
    on<SilentRefreshHomeDataEvent>(_onSilentRefreshHomeData);
    on<ToggleAreaSelectionEvent>(_onToggleAreaSelection);
    on<ToggleAreaWatchEvent>(_onToggleAreaWatch);
    on<SelectDisplayAreaEvent>(_onSelectDisplayArea);
    on<ClearMonitoredAreaSelectionEvent>(_onClearMonitoredAreaSelection);
    on<LoadMoreSchedulesEvent>(_onLoadMoreSchedules);
    on<ToggleAreaItemEvent>(_onToggleAreaItem);
    on<UpdateWatchedLocationEvent>(_onUpdateWatchedLocation);
    on<RefreshProfileDefaultLocationEvent>(_onRefreshProfileDefaultLocation);

    // Hierarchy
    on<FetchRegionsEvent>(_onFetchRegions);
    on<SelectRegionEvent>(_onSelectRegion);
    on<SelectUnitEvent>(_onSelectUnit);
    on<SelectNeighborhoodEvent>(_onSelectNeighborhood);
    on<SelectZoneEvent>(_onSelectZone);
    on<ToggleGlobalLocationModeEvent>(_onToggleGlobalLocationMode);

    // Deep link from notification tap
    on<NavigateFromNotificationEvent>(_onNavigateFromNotification);
  }

  final GetWatchedAreasUseCase _getWatchedAreas;
  final GetPumpingStatusUseCase _getPumpingStatus;
  final GetUpcomingSchedulesUseCase _getUpcomingSchedules;
  final ToggleAreaWatchUseCase _toggleAreaWatch;
  final IHierarchyRepository _hierarchyRepository;
  final IProfileRepository _profileRepository;
  final SecureStorage _secureStorage;
  StreamSubscription<void>? _profileSubscription;
  StreamSubscription<RemoteMessage>? _notificationSubscription;

  static const _pumpingChangeTypes = {
    'SCHEDULE_CANCELLED',
    'PUMPING_CANCELLED',
    'PUMPING_STARTED',
    'PUMPING_ENDED',
    'PUMPING_START',
    'PUMPING_STOP',
    'PUMPING_PAUSED',
    'PUMPING_RESUMED',
    'SCHEDULE_UPDATED',
    'SCHEDULE_ACTIVATED',
  };

  void _onPushNotification(RemoteMessage message) {
    final type = (message.data['type'] ?? '').toString().toUpperCase();
    if (_pumpingChangeTypes.contains(type)) {
      // A pumping change invalidates any cached non-default zone status.
      _getPumpingStatus.clearCache();
      add(LoadHomeDataEvent());
    }
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Distinguish first load (full-page shimmer) from silent refresh
    // (small header animation while data updates in the background).
    emit(
      state.copyWith(
        isLoading: state.isFirstLoad,
        isRefreshing: !state.isFirstLoad,
        clearError: true,
      ),
    );

    // 1. Fetch User Profile once to determine role and default locations
    final userResult = await _profileRepository.getProfile();

    await userResult.fold(
      (failure) async {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: failure.errMessage,
          ),
        );
      },
      (user) async {
        // 2. Prefer persisted default address from SecureStorage, fallback to
        // profile effective default location. Citizens must use default*, not
        // watched*, because home pumping status is scoped to the default address.
        final selectedHomeAddress = await _loadSelectedHomeAddress();
        final effectiveRegionId =
            selectedHomeAddress != null && selectedHomeAddress.regionId > 0
            ? selectedHomeAddress.regionId
            : (user.effectiveRegionId > 0 ? user.effectiveRegionId : null);
        final effectiveUnitId =
            selectedHomeAddress != null && selectedHomeAddress.unitId > 0
            ? selectedHomeAddress.unitId
            : (user.effectiveUnitId > 0 ? user.effectiveUnitId : null);
        final effectiveNeighborhoodId =
            selectedHomeAddress != null &&
                selectedHomeAddress.neighborhoodId > 0
            ? selectedHomeAddress.neighborhoodId
            : (user.effectiveNeighborhoodId > 0
                  ? user.effectiveNeighborhoodId
                  : null);
        final effectiveZoneId =
            selectedHomeAddress != null && (selectedHomeAddress.zoneId ?? 0) > 0
            ? selectedHomeAddress.zoneId
            : (user.effectiveZoneId > 0 ? user.effectiveZoneId : null);

        // Determine filter IDs (only if not already set)
        final keepExplicitMonitoredSelection =
            state.selectedMonitoredArea != null;
        final neighborhoodId = state.isGlobalLocationMode
            ? null
            : (keepExplicitMonitoredSelection
                  ? (state.filteredNeighborhoodId ?? effectiveNeighborhoodId)
                  : effectiveNeighborhoodId);
        final zoneId = state.isGlobalLocationMode
            ? null
            : (keepExplicitMonitoredSelection
                  ? (state.filteredZoneId ?? effectiveZoneId)
                  : effectiveZoneId);

        // Build location name from selectedHomeAddress, then watched location
        var locationName = state.filteredLocationName;
        if (locationName == null || locationName.isEmpty) {
          locationName = selectedHomeAddress?.locationName.isNotEmpty ?? false
              ? selectedHomeAddress!.locationName
              : (user.effectiveZoneName ??
                    user.effectiveNeighborhoodName ??
                    user.effectiveUnitName ??
                    user.effectiveRegionName);
        }

        // Update state with user object and hierarchy IDs (from selected address or watched location)
        emit(
          state.copyWith(
            user: user,
            filteredNeighborhoodId: neighborhoodId,
            filteredZoneId: zoneId,
            filteredLocationName: locationName,
            selectedRegionId: effectiveRegionId,
            selectedUnitId: effectiveUnitId,
            selectedNeighborhoodId: effectiveNeighborhoodId,
            selectedZoneId: effectiveZoneId,
          ),
        );

        // 3. Fetch hierarchy data so dropdowns render labels correctly
        await _initializeHierarchyFromProfile(emit, user);

        // 4. Fetch everything else in parallel
        await Future.wait([
          _loadWatchedAreas(emit),
          _loadPumpingStatus(
            emit,
            regionId: effectiveRegionId,
            neighborhoodId: neighborhoodId,
            zoneId: zoneId,
            isDefault: _isDefaultHomeLocation(
              user: user,
              zoneId: zoneId,
              neighborhoodId: neighborhoodId,
            ),
          ),
          _loadUpcomingSchedules(emit, user: user, refresh: true),
        ]);

        // 5. After loading watched areas, if monitoredAreas is empty,
        //    ensure filteredLocationName reflects the selected/watched zone name
        if (state.monitoredAreas.isEmpty) {
          final effectiveLocationName =
              selectedHomeAddress?.locationName.isNotEmpty ?? false
              ? selectedHomeAddress!.locationName
              : (user.effectiveZoneName ??
                    user.effectiveNeighborhoodName ??
                    user.effectiveRegionName);

          if (effectiveLocationName != null &&
              effectiveLocationName.isNotEmpty) {
            emit(
              state.copyWith(
                filteredLocationName: effectiveLocationName,
              ),
            );
          }
        }
      },
    );

    emit(
      state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isFirstLoad: false,
      ),
    );
  }

  /// Fetches hierarchy data (regions, units, neighborhoods, zones) and
  /// auto-selects the user's profile location. This populates the dropdowns
  /// in WatchedLocationBottomSheet with the correct pre-selected values.
  ///
  /// IMPORTANT: Fetches ALL levels independently — if a unit is not found,
  /// it still fetches neighborhoods and zones so the dropdowns are populated.
  Future<void> _initializeHierarchyFromProfile(
    Emitter<HomeState> emit,
    UserEntity user,
  ) async {
    final regionId = state.selectedRegionId;
    final expectedUnitId = state.selectedUnitId;
    final expectedNeighborhoodId = state.selectedNeighborhoodId;
    final expectedZoneId = state.selectedZoneId;

    // Level 1: Fetch regions
    final regionsResult = await _hierarchyRepository.getRegions();
    regionsResult.fold(
      (f) => emit(state.copyWith(errorMessage: f.errMessage)),
      (regions) => emit(state.copyWith(regions: regions)),
    );

    // Level 2: Fetch units (always, so dropdown is populated)
    if (regionId != null && regionId > 0) {
      final unitsResult = await _hierarchyRepository.getUnits(regionId);
      unitsResult.fold(
        (f) => emit(state.copyWith(errorMessage: f.errMessage)),
        (units) => emit(state.copyWith(units: units)),
      );
    }

    // Level 3: Fetch neighborhoods (always, so dropdown is populated)
    if (regionId != null && regionId > 0) {
      final nhResult = await _hierarchyRepository.getNeighborhoods(regionId);
      nhResult.fold(
        (f) => emit(state.copyWith(errorMessage: f.errMessage)),
        (neighborhoods) => emit(state.copyWith(neighborhoods: neighborhoods)),
      );
    }

    // Level 4: Fetch zones (always, so dropdown is populated)
    if (regionId != null && regionId > 0) {
      final zonesResult = await _hierarchyRepository.getZones(regionId);
      zonesResult.fold(
        (f) => emit(state.copyWith(errorMessage: f.errMessage)),
        (zones) => emit(state.copyWith(zones: zones)),
      );
    }

    // === Determine the display name from the loaded data ===
    // Show only the zone name (or neighborhood if zone not found)
    final currentZones = state.zones;
    final currentNeighborhoods = state.neighborhoods;
    final currentUnits = state.units;
    final currentRegions = state.regions;

    // Try zone first (most specific - what we want to display)
    if (expectedZoneId != null && currentZones.isNotEmpty) {
      final zone = currentZones
          .where((e) => e.id == expectedZoneId)
          .firstOrNull;
      if (zone != null) {
        emit(
          state.copyWith(
            filteredZoneId: expectedZoneId,
            filteredLocationName: zone.name,
          ),
        );
        return;
      }
    }

    // Try neighborhood
    if (expectedNeighborhoodId != null && currentNeighborhoods.isNotEmpty) {
      final nh = currentNeighborhoods
          .where((e) => e.id == expectedNeighborhoodId)
          .firstOrNull;
      if (nh != null) {
        emit(
          state.copyWith(
            filteredNeighborhoodId: expectedNeighborhoodId,
            filteredLocationName: nh.name,
          ),
        );
        return;
      }
    }

    // Try unit
    if (expectedUnitId != null && currentUnits.isNotEmpty) {
      final unit = currentUnits
          .where((e) => e.id == expectedUnitId)
          .firstOrNull;
      if (unit != null) {
        emit(state.copyWith(filteredLocationName: unit.name));
        return;
      }
    }

    // Fallback: use region name from loaded regions list
    if (regionId != null && regionId > 0 && currentRegions.isNotEmpty) {
      final region = currentRegions.where((e) => e.id == regionId).firstOrNull;
      if (region != null) {
        emit(state.copyWith(filteredLocationName: region.name));
        return;
      }
    }

    // Fallback: use effective default/profile region name.
    if (user.effectiveRegionName != null &&
        user.effectiveRegionName!.isNotEmpty) {
      emit(state.copyWith(filteredLocationName: user.effectiveRegionName));
    }
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Explicit pull-to-refresh should bypass the short-TTL zone cache.
    _getPumpingStatus.clearCache();
    emit(state.copyWith(isRefreshing: true));
    add(LoadHomeDataEvent());
  }

  /// Triggered automatically when the user switches back to the Home tab.
  /// Reuses the same load logic as [LoadHomeDataEvent] but guarantees
  /// [isRefreshing] is true so the UI shows the small header animation
  /// instead of the full-page shimmer.
  Future<void> _onSilentRefreshHomeData(
    SilentRefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    add(LoadHomeDataEvent());
  }

  /// Whether the location being queried is the user's own default home.
  /// Only the default home is correctly served by the consolidated
  /// `/schedules/home-status` endpoint (scoped server-side to the authenticated
  /// user). Any other saved address or monitored area points at a different
  /// zone/neighbourhood and must be fetched via the zone endpoint instead.
  bool _isDefaultHomeLocation({
    required UserEntity user,
    int? zoneId,
    int? neighborhoodId,
  }) {
    final homeZoneId = user.effectiveZoneId;
    final homeNeighborhoodId = user.effectiveNeighborhoodId;

    if (zoneId != null && zoneId > 0) {
      return homeZoneId > 0 && zoneId == homeZoneId;
    }
    if (neighborhoodId != null && neighborhoodId > 0) {
      return homeNeighborhoodId > 0 && neighborhoodId == homeNeighborhoodId;
    }
    // No specific zone/neighbourhood to compare against (region-only or global
    // mode) → the consolidated home endpoint applies.
    return true;
  }

  Future<void> _loadPumpingStatus(
    Emitter<HomeState> emit, {
    int? regionId,
    int? neighborhoodId,
    int? zoneId,
    bool isDefault = true,
    bool refresh = false,
  }) async {
    final result = await _getPumpingStatus(
      regionId: regionId,
      neighborhoodId: neighborhoodId,
      zoneId: zoneId,
      isDefault: isDefault,
    );

    result.fold(
      (failure) {
        if (!refresh && state.pumpingStatus.isEmpty) {
          emit(state.copyWith(errorMessage: failure.errMessage));
        }
      },
      (status) {
        AppLogger.debug(
          'HOME_PUMPING count=${status.length} ids=${status.map((e) => e.scheduleId).toList()} statuses=${status.map((e) => e.status.name).toList()}',
        );
        emit(state.copyWith(pumpingStatus: status));
      },
    );
  }

  Future<void> _loadUpcomingSchedules(
    Emitter<HomeState> emit, {
    required UserEntity user,
    bool refresh = false,
  }) async {
    final currentPage = refresh ? 0 : state.schedulesPage + 1;

    List<int>? unitIds;
    var regionId = state.user?.isEmployee ?? false
        ? state.user?.watchedRegionId
        : (state.selectedRegionId ?? state.user?.effectiveRegionId);
    var neighborhoodId = state.filteredNeighborhoodId;
    var zoneId = state.filteredZoneId;

    if (state.isGlobalLocationMode && user.isCitizen) {
      regionId = null;
      neighborhoodId = null;
      zoneId = null;
      unitIds = null;
    } else if (user.isEmployee) {
      if (neighborhoodId == null && zoneId == null) {
        if (state.monitoredAreas.isNotEmpty) {
          unitIds = state.monitoredAreas.map((e) => e.id).toList();
        } else if (user.assignedUnits.isNotEmpty) {
          unitIds = user.assignedUnits;
        }
      }
    } else if (user.isCitizen) {
      // If a specific monitored area is selected, use its ID as the filter.
      // filteredNeighborhoodId/filteredZoneId are already set by _onSelectDisplayArea.
      // Fall back to user's profile defaults if nothing is set.
      if (neighborhoodId == null && zoneId == null) {
        neighborhoodId = user.effectiveNeighborhoodId > 0
            ? user.effectiveNeighborhoodId
            : null;
        zoneId = user.effectiveZoneId > 0 ? user.effectiveZoneId : null;
      }
    }

    final result = await _getUpcomingSchedules(
      page: currentPage,
      regionId: regionId,
      neighborhoodId: neighborhoodId,
      zoneId: zoneId,
      unitIds: unitIds,
    );

    result.fold(
      (failure) {
        if (!refresh && state.schedules.isEmpty) {
          emit(state.copyWith(errorMessage: failure.errMessage));
        }
      },
      (pagination) {
        final newSchedules = refresh
            ? pagination.content
            : [...state.schedules, ...pagination.content];

        AppLogger.debug(
          'HOME_SCHEDULES count=${newSchedules.length} ids=${newSchedules.map((e) => e.id).toList()} statuses=${newSchedules.map((e) => e.status.name).toList()}',
        );

        emit(
          state.copyWith(
            schedules: newSchedules,
            schedulesPage: currentPage,
            hasMoreSchedules: !pagination.isLast,
          ),
        );
      },
    );
  }

  Future<void> _loadWatchedAreas(
    Emitter<HomeState> emit, {
    bool refresh = false,
  }) async {
    final result = await _getWatchedAreas();

    result.fold(
      (failure) {
        if (!refresh && state.watchedAreas.isEmpty) {
          emit(
            state.copyWith(
              errorMessage: failure.errMessage,
              watchedAreas: [],
              monitoredAreas: [],
            ),
          );
        }
      },
      (areas) {
        final monitored = areas.where((a) => a.isWatched).toList();
        emit(
          state.copyWith(
            watchedAreas: areas,
            monitoredAreas: monitored,
          ),
        );
      },
    );
  }

  /// Updates the display location when the user taps a monitored area chip.
  /// Sets [filteredNeighborhoodId] / [filteredZoneId] and [selectedMonitoredArea]
  /// so that pump status and schedules reflect the selected area.
  Future<void> _onSelectDisplayArea(
    SelectDisplayAreaEvent event,
    Emitter<HomeState> emit,
  ) async {
    final area = state.monitoredAreas
        .where((a) => a.id == event.areaId)
        .firstOrNull;
    if (area == null) return;

    // Toggle: if the same area is tapped again, clear the selection
    if (state.selectedMonitoredArea?.id == event.areaId) {
      add(ClearMonitoredAreaSelectionEvent());
      return;
    }

    final hasZone = area.zoneName.isNotEmpty;
    final hasNeighborhood = area.neighborhoodName.isNotEmpty;

    final regionEntity = state.regions
        .where((r) => r.name == area.regionName)
        .firstOrNull;
    final areaRegionId = regionEntity?.id;

    final areaNeighborhoodId = hasNeighborhood && !hasZone ? area.id : null;
    final areaZoneId = hasZone ? area.id : null;

    emit(
      state.copyWith(
        selectedMonitoredArea: area,
        filteredNeighborhoodId: areaNeighborhoodId,
        filteredZoneId: areaZoneId,
        filteredLocationName: area.name,
        isLoading: true,
      ),
    );

    final userResult = await _profileRepository.getProfile();
    await userResult.fold(
      (f) async =>
          emit(state.copyWith(isLoading: false, errorMessage: f.errMessage)),
      (user) async {
        await _loadPumpingStatus(
          emit,
          regionId:
              areaRegionId ??
              (user.watchedRegionId > 0 ? user.watchedRegionId : null),
          neighborhoodId: areaNeighborhoodId,
          zoneId: areaZoneId,
          isDefault: _isDefaultHomeLocation(
            user: user,
            zoneId: areaZoneId,
            neighborhoodId: areaNeighborhoodId,
          ),
          refresh: true,
        );
        await _loadUpcomingSchedules(emit, user: user, refresh: true);
        emit(state.copyWith(isLoading: false));
      },
    );
  }

  /// Reverts to the profile's default location, clearing any selected monitored area.
  Future<void> _onClearMonitoredAreaSelection(
    ClearMonitoredAreaSelectionEvent event,
    Emitter<HomeState> emit,
  ) async {
    final user = state.user;
    if (user == null) return;

    final selectedHomeAddress = await _loadSelectedHomeAddress();
    final effectiveNeighborhoodId =
        selectedHomeAddress != null && selectedHomeAddress.neighborhoodId > 0
        ? selectedHomeAddress.neighborhoodId
        : (user.effectiveNeighborhoodId > 0
              ? user.effectiveNeighborhoodId
              : null);
    final effectiveZoneId =
        selectedHomeAddress != null && (selectedHomeAddress.zoneId ?? 0) > 0
        ? selectedHomeAddress.zoneId
        : (user.effectiveZoneId > 0 ? user.effectiveZoneId : null);
    final effectiveRegionId =
        selectedHomeAddress != null && selectedHomeAddress.regionId > 0
        ? selectedHomeAddress.regionId
        : (user.effectiveRegionId > 0 ? user.effectiveRegionId : null);
    final effectiveLocationName =
        selectedHomeAddress?.locationName.isNotEmpty ?? false
        ? selectedHomeAddress!.locationName
        : (user.effectiveZoneName ??
              user.effectiveNeighborhoodName ??
              user.effectiveUnitName ??
              user.effectiveRegionName);

    emit(
      state.copyWith(
        clearSelectedMonitoredArea: true,
        filteredNeighborhoodId: effectiveNeighborhoodId,
        filteredZoneId: effectiveZoneId,
        filteredLocationName: effectiveLocationName,
        isLoading: true,
      ),
    );

    await Future.wait([
      _loadPumpingStatus(
        emit,
        regionId: effectiveRegionId,
        neighborhoodId: effectiveNeighborhoodId,
        zoneId: effectiveZoneId,
        isDefault: _isDefaultHomeLocation(
          user: user,
          zoneId: effectiveZoneId,
          neighborhoodId: effectiveNeighborhoodId,
        ),
        refresh: true,
      ),
      _loadUpcomingSchedules(emit, user: user, refresh: true),
    ]);

    emit(state.copyWith(isLoading: false));
  }

  void _onToggleAreaSelection(
    ToggleAreaSelectionEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(
      state.copyWith(isAreaSelectionExpanded: !state.isAreaSelectionExpanded),
    );
  }

  Future<void> _onToggleAreaWatch(
    ToggleAreaWatchEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Optimistic update
    final updatedAreas = state.watchedAreas.map((area) {
      if (area.id == event.areaId) {
        return area.copyWith(isWatched: event.watch);
      }
      return area;
    }).toList();

    final updatedMonitored = updatedAreas.where((a) => a.isWatched).toList();

    emit(
      state.copyWith(
        watchedAreas: updatedAreas,
        monitoredAreas: updatedMonitored,
      ),
    );

    final result = await _toggleAreaWatch(
      areaId: event.areaId,
      watch: event.watch,
    );

    result.fold(
      (failure) {
        // Rollback on error
        final rolledBackAreas = state.watchedAreas.map((area) {
          if (area.id == event.areaId) {
            return area.copyWith(isWatched: !event.watch);
          }
          return area;
        }).toList();
        final rolledBackMonitored = rolledBackAreas
            .where((a) => a.isWatched)
            .toList();

        emit(
          state.copyWith(
            watchedAreas: rolledBackAreas,
            monitoredAreas: rolledBackMonitored,
            errorMessage: failure.errMessage,
          ),
        );
      },
      (_) async {
        // If the removed area was the one being viewed, clear the selection
        final wasSelectedArea =
            !event.watch && state.selectedMonitoredArea?.id == event.areaId;

        // Success - refresh data
        final userResult = await _profileRepository.getProfile();
        await userResult.fold(
          (f) async => emit(state.copyWith(errorMessage: f.errMessage)),
          (user) async {
            if (wasSelectedArea) {
              // Revert to profile default since the viewed area was removed
              add(ClearMonitoredAreaSelectionEvent());
              return;
            }

            // Re-initialize hierarchy from updated profile (using watched location)
            emit(
              state.copyWith(
                user: user,
                selectedRegionId: user.watchedRegionId > 0
                    ? user.watchedRegionId
                    : null,
                selectedUnitId: user.watchedUnitId > 0
                    ? user.watchedUnitId
                    : null,
                selectedNeighborhoodId: user.watchedNeighborhoodId > 0
                    ? user.watchedNeighborhoodId
                    : null,
                selectedZoneId: user.watchedZoneId > 0
                    ? user.watchedZoneId
                    : null,
              ),
            );
            await _initializeHierarchyFromProfile(emit, user);

            await Future.wait([
              _loadPumpingStatus(
                emit,
                regionId: user.watchedRegionId > 0
                    ? user.watchedRegionId
                    : null,
                neighborhoodId: state.filteredNeighborhoodId,
                zoneId: state.filteredZoneId,
                isDefault: _isDefaultHomeLocation(
                  user: user,
                  zoneId: state.filteredZoneId,
                  neighborhoodId: state.filteredNeighborhoodId,
                ),
                refresh: true,
              ),
              _loadUpcomingSchedules(emit, user: user, refresh: true),
            ]);
          },
        );
      },
    );
  }

  Future<void> _onLoadMoreSchedules(
    LoadMoreSchedulesEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (!state.hasMoreSchedules || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));

    final userResult = await _profileRepository.getProfile();
    await userResult.fold(
      (f) async => emit(
        state.copyWith(isLoadingMore: false, errorMessage: f.errMessage),
      ),
      (user) async {
        await _loadUpcomingSchedules(emit, user: user);
        emit(state.copyWith(isLoadingMore: false));
      },
    );
  }

  void _onToggleAreaItem(
    ToggleAreaItemEvent event,
    Emitter<HomeState> emit,
  ) {
    // This seems unused or redundant now, but keeping for compatibility
  }

  Future<void> _onUpdateWatchedLocation(
    UpdateWatchedLocationEvent event,
    Emitter<HomeState> emit,
  ) async {
    // If neighborhoodId is provided, we add it to watched areas
    if (event.neighborhoodId != null) {
      add(ToggleAreaWatchEvent(areaId: event.neighborhoodId!, watch: true));
    } else if (event.zoneId != null) {
      add(ToggleAreaWatchEvent(areaId: event.zoneId!, watch: true));
    }

    // Sync the selected hierarchy IDs with the filter IDs for API queries
    emit(
      state.copyWith(
        filteredNeighborhoodId: event.neighborhoodId,
        filteredZoneId: event.zoneId,
        filteredLocationName: event.locationName,
        isGlobalLocationMode: false,
        selectedNeighborhoodId:
            event.neighborhoodId ?? state.selectedNeighborhoodId,
        selectedZoneId: event.zoneId ?? state.selectedZoneId,
        isLoading: true,
      ),
    );

    final userResult = await _profileRepository.getProfile();
    await userResult.fold(
      (f) async =>
          emit(state.copyWith(isLoading: false, errorMessage: f.errMessage)),
      (user) async {
        // Update hierarchy state from refreshed profile
        emit(
          state.copyWith(
            user: user,
            selectedRegionId: user.isCitizen
                ? (user.defaultRegionId > 0 ? user.defaultRegionId : null)
                : (user.watchedRegionId > 0 ? user.watchedRegionId : null),
            selectedUnitId: user.isCitizen
                ? (user.defaultUnitId > 0 ? user.defaultUnitId : null)
                : (user.watchedUnitId > 0 ? user.watchedUnitId : null),
          ),
        );
        await _initializeHierarchyFromProfile(emit, user);

        await Future.wait([
          _loadPumpingStatus(
            emit,
            regionId: user.defaultRegionId > 0 ? user.defaultRegionId : null,
            neighborhoodId: event.neighborhoodId,
            zoneId: event.zoneId,
            isDefault: _isDefaultHomeLocation(
              user: user,
              zoneId: event.zoneId,
              neighborhoodId: event.neighborhoodId,
            ),
            refresh: true,
          ),
          _loadUpcomingSchedules(emit, user: user, refresh: true),
        ]);
        emit(state.copyWith(isLoading: false));
      },
    );
  }

  // Hierarchy Logic
  Future<void> _onFetchRegions(
    FetchRegionsEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isRegionsLoading: true));
    final result = await _hierarchyRepository.getRegions();
    result.fold(
      (f) => emit(
        state.copyWith(isRegionsLoading: false, errorMessage: f.errMessage),
      ),
      (list) {
        emit(state.copyWith(isRegionsLoading: false, regions: list));
        if (list.length == 1) {
          add(SelectRegionEvent(list.first.id));
        }
      },
    );
  }

  Future<void> _onSelectRegion(
    SelectRegionEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Guard: avoid redundant work when the user re-selects the same region.
    if (state.selectedRegionId == event.regionId) return;

    // Find the region name for display
    final regionName = state.regions
        .where((e) => e.id == event.regionId)
        .firstOrNull
        ?.name;

    emit(
      state.copyWith(
        selectedRegionId: event.regionId,
        resetUnits: true,
        resetNeighborhoods: true,
        resetZones: true,
        isUnitsLoading: true,
        clearFilter: true, // Clear filter when changing region
        filteredLocationName: regionName ?? state.filteredLocationName,
      ),
    );

    final result = await _hierarchyRepository.getUnits(event.regionId);
    result.fold(
      (f) => emit(
        state.copyWith(isUnitsLoading: false, errorMessage: f.errMessage),
      ),
      (list) {
        emit(state.copyWith(isUnitsLoading: false, units: list));
        if (list.length == 1) {
          add(SelectUnitEvent(list.first.id));
        }
      },
    );
  }

  Future<void> _onSelectUnit(
    SelectUnitEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Guard: avoid redundant work when the user re-selects the same unit.
    if (state.selectedUnitId == event.unitId) return;

    emit(
      state.copyWith(
        selectedUnitId: event.unitId,
        resetNeighborhoods: true,
        resetZones: true,
        isNeighborhoodsLoading: true,
        clearFilter: true,
      ),
    );

    final result = await _hierarchyRepository.getNeighborhoods(
      state.selectedRegionId ?? 0,
    );
    result.fold(
      (f) => emit(
        state.copyWith(
          isNeighborhoodsLoading: false,
          errorMessage: f.errMessage,
        ),
      ),
      (list) {
        final unitName = state.units
            .where((e) => e.id == event.unitId)
            .firstOrNull
            ?.name;
        emit(
          state.copyWith(
            isNeighborhoodsLoading: false,
            neighborhoods: list,
            filteredLocationName: unitName ?? state.filteredLocationName,
          ),
        );
        if (list.length == 1) {
          add(SelectNeighborhoodEvent(list.first.id));
        }
      },
    );
  }

  Future<void> _onSelectNeighborhood(
    SelectNeighborhoodEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Guard: avoid redundant work when the user re-selects the same neighborhood.
    if (state.selectedNeighborhoodId == event.neighborhoodId) return;

    emit(
      state.copyWith(
        selectedNeighborhoodId: event.neighborhoodId,
        resetZones: true,
        isZonesLoading: true,
        filteredNeighborhoodId: event.neighborhoodId,
      ),
    );

    final result = await _hierarchyRepository.getZones(
      state.selectedRegionId ?? 0,
    );
    result.fold(
      (f) => emit(
        state.copyWith(isZonesLoading: false, errorMessage: f.errMessage),
      ),
      (list) {
        final nhName = state.neighborhoods
            .where((e) => e.id == event.neighborhoodId)
            .firstOrNull
            ?.name;
        emit(
          state.copyWith(
            isZonesLoading: false,
            zones: list,
            filteredLocationName: nhName ?? state.filteredLocationName,
          ),
        );
        if (list.length == 1) {
          add(SelectZoneEvent(list.first.id));
        }
      },
    );
  }

  Future<void> _onSelectZone(
    SelectZoneEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Guard: avoid redundant work when the user re-selects the same zone.
    if (state.selectedZoneId == event.zoneId) return;

    // Find the zone name for display
    final zoneName = state.zones
        .where((e) => e.id == event.zoneId)
        .firstOrNull
        ?.name;

    emit(
      state.copyWith(
        selectedZoneId: event.zoneId,
        filteredZoneId: event.zoneId,
        filteredLocationName: zoneName ?? state.filteredLocationName,
      ),
    );
  }

  /// Handles deep link from notification tap.
  /// Sets the location context from the notification payload and refreshes data.
  Future<void> _onNavigateFromNotification(
    NavigateFromNotificationEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Build location name from the notification payload
    final parts = <String>[];
    if (event.regionName != null && event.regionName!.isNotEmpty) {
      parts.add(event.regionName!);
    }
    if (event.unitName != null && event.unitName!.isNotEmpty) {
      parts.add(event.unitName!);
    }
    if (event.neighborhoodName != null && event.neighborhoodName!.isNotEmpty) {
      parts.add(event.neighborhoodName!);
    }
    if (event.zoneName != null && event.zoneName!.isNotEmpty) {
      parts.add(event.zoneName!);
    }
    final locationName = parts.isEmpty ? null : parts.join(' - ');

    emit(
      state.copyWith(
        filteredLocationName: locationName ?? state.filteredLocationName,
      ),
    );

    // Refresh home data with the new location context
    add(LoadHomeDataEvent());
  }

  /// Handles refresh of default location after user edits their profile.
  /// Fetches the updated profile, syncs the effective zone name to state,
  /// and refreshes pumping status and schedules with the new location criteria.
  Future<void> _onRefreshProfileDefaultLocation(
    RefreshProfileDefaultLocationEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearError: true));

    final userResult = await _profileRepository.getProfile();
    // await the fold so async callbacks complete before returning
    await userResult.fold(
      (failure) async => emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: failure.errMessage,
        ),
      ),
      (user) async {
        // Prefer selectedHomeAddress from SecureStorage, fallback to watched location
        final selectedHomeAddress = await _loadSelectedHomeAddress();
        final effectiveLocationName =
            selectedHomeAddress != null &&
                selectedHomeAddress.locationName.isNotEmpty
            ? selectedHomeAddress.locationName
            : (user.effectiveZoneName ??
                  user.effectiveNeighborhoodName ??
                  user.effectiveUnitName ??
                  user.effectiveRegionName);

        // Prefer selectedHomeAddress, then effective location (default > watched)
        // using effectiveXxxId so citizens get their defaultXxxId, not watchedXxxId=0
        final refreshRegionId =
            selectedHomeAddress != null && selectedHomeAddress.regionId > 0
            ? selectedHomeAddress.regionId
            : (user.effectiveRegionId > 0 ? user.effectiveRegionId : null);
        final refreshUnitId =
            selectedHomeAddress != null && selectedHomeAddress.unitId > 0
            ? selectedHomeAddress.unitId
            : (user.effectiveUnitId > 0 ? user.effectiveUnitId : null);
        final refreshNeighborhoodId =
            selectedHomeAddress != null &&
                selectedHomeAddress.neighborhoodId > 0
            ? selectedHomeAddress.neighborhoodId
            : (user.effectiveNeighborhoodId > 0
                  ? user.effectiveNeighborhoodId
                  : null);
        final refreshZoneId =
            selectedHomeAddress != null && (selectedHomeAddress.zoneId ?? 0) > 0
            ? selectedHomeAddress.zoneId
            : (user.effectiveZoneId > 0 ? user.effectiveZoneId : null);

        // Always emit location IDs so _loadUpcomingSchedules reads correct values.
        // copyWith keeps old value when null is passed, so refreshZoneId must be
        // non-null when the zone actually changed — effectiveZoneId guarantees this
        // for citizens (returns defaultZoneId, not watchedZoneId which may be 0).
        emit(
          state.copyWith(
            isRefreshing: true,
            user: user,
            filteredLocationName: effectiveLocationName,
            filteredNeighborhoodId: refreshNeighborhoodId,
            filteredZoneId: refreshZoneId,
            selectedRegionId: refreshRegionId,
            selectedUnitId: refreshUnitId,
            selectedNeighborhoodId: refreshNeighborhoodId,
            selectedZoneId: refreshZoneId,
            clearSelectedMonitoredArea: true,
          ),
        );

        // Refresh pumping status and schedules with effective location
        await Future.wait([
          _loadPumpingStatus(
            emit,
            regionId: refreshRegionId,
            neighborhoodId: refreshNeighborhoodId,
            zoneId: refreshZoneId,
            isDefault: _isDefaultHomeLocation(
              user: user,
              zoneId: refreshZoneId,
              neighborhoodId: refreshNeighborhoodId,
            ),
            refresh: true,
          ),
          _loadUpcomingSchedules(emit, user: user, refresh: true),
        ]);

        emit(state.copyWith(isRefreshing: false));
      },
    );
  }

  Future<SelectedHomeAddress?> _loadSelectedHomeAddress() async {
    final addressId = await _secureStorage.getSelectedHomeAddressId();
    if (addressId == null) return null;

    final regionId = await _secureStorage.getSelectedHomeRegionId();
    final unitId = await _secureStorage.getSelectedHomeUnitId();
    final neighborhoodId = await _secureStorage.getSelectedHomeNeighborhoodId();
    final zoneId = await _secureStorage.getSelectedHomeZoneId();
    final locationName =
        await _secureStorage.getSelectedHomeLocationName() ?? '';

    if (regionId == null || unitId == null || neighborhoodId == null) {
      return null;
    }

    return SelectedHomeAddress(
      addressId: addressId,
      regionId: regionId,
      unitId: unitId,
      neighborhoodId: neighborhoodId,
      zoneId: zoneId,
      locationName: locationName,
    );
  }

  // ===========================================================================
  // GLOBAL LOCATION MODE
  // ===========================================================================

  void _onToggleGlobalLocationMode(
    ToggleGlobalLocationModeEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(isGlobalLocationMode: event.enabled));
  }

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    _notificationSubscription?.cancel();
    return super.close();
  }
}

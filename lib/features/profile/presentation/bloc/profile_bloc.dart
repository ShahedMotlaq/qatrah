// lib/features/profile/presentation/bloc/profile_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/events/profile_event_bus.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';
import 'package:qatrah/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:qatrah/features/profile/domain/usecases/get_hierarchy_usecases.dart';
import 'package:qatrah/features/profile/domain/usecases/update_profile_usecases.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_event.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_state.dart';

class EditProfileBloc extends Bloc<ProfileEvent, EditProfileState> {
  EditProfileBloc(
    this._getRegions,
    this._getUnits,
    this._getNeighborhoods,
    this._getZones,
    this._updateProfile,
    this._repository,
  ) : super(const EditProfileState()) {
    on<LoadInitialProfileData>(_onLoadProfile);
    on<LoadUserLocationsEvent>(_onLoadUserLocations);
    on<GetRegionsEvent>(_onGetRegions);
    on<ResetLocationSelectionEvent>(_onResetLocationSelection);
    on<LocationSelectionChanged>(_onLocationChanged);
    on<NameChangedEvent>(_onNameChanged);
    on<SubmitProfileEvent>(_onSubmitProfile);
    on<NavigateAfterCompleteEvent>(_onNavigateAfterComplete);
    on<ApplySavedLocationSelection>(_onApplySavedLocationSelection);
    on<ResetFormEvent>(_onResetForm);
  }
  final GetRegionsUseCase _getRegions;
  final GetUnitsUseCase _getUnits;
  final GetNeighborhoodsUseCase _getNeighborhoods;
  final GetZonesUseCase _getZones;
  final UpdateProfileUseCase _updateProfile;
  final IProfileRepository _repository;

  LocationLookupEntity? _lookupFromName(int id, String? name) {
    final trimmedName = name?.trim();
    if (trimmedName == null || trimmedName.isEmpty) return null;
    return LocationLookupEntity(id: id, name: trimmedName);
  }

  Future<void> _onLoadProfile(
    LoadInitialProfileData event,
    Emitter<EditProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, isSuccess: false, clearError: true));

    // Brief delay to ensure the token is saved and activated in SecureStorage
    await Future.delayed(const Duration(milliseconds: 100));

    final result = await _repository.getProfile();
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.errMessage)),
      (user) {
        emit(
          state.copyWith(
            isLoading: false,
            user: user,
            fullName: user.fullName,
            // Initial mapping of IDs to prevent "No location selected"
            // API may return 0 for IDs but still has name data — map both
            selectedRegionId: user.isEmployee
                ? user.watchedRegionId
                : user.defaultRegionId,
            selectedUnitId: user.isEmployee
                ? user.watchedUnitId
                : user.defaultUnitId,
            selectedNeighborhoodId: user.isEmployee
                ? user.watchedNeighborhoodId
                : user.defaultNeighborhoodId,
            selectedZoneId: user.isEmployee
                ? user.watchedZoneId
                : user.defaultZoneId,
            // Also set LocationLookupEntity from names so hasDefaultLocation works immediately
            defaultRegion: user.isCitizen
                ? _lookupFromName(user.defaultRegionId, user.defaultRegionName)
                : null,
            defaultUnit: user.isCitizen
                ? _lookupFromName(user.defaultUnitId, user.defaultUnitName)
                : null,
            defaultNeighborhood: user.isCitizen
                ? _lookupFromName(
                    user.defaultNeighborhoodId,
                    user.defaultNeighborhoodName,
                  )
                : null,
            defaultZone: user.isCitizen
                ? _lookupFromName(user.defaultZoneId, user.defaultZoneName)
                : null,
            watchedRegion: user.isEmployee
                ? _lookupFromName(user.watchedRegionId, user.watchedRegionName)
                : null,
            watchedUnit: user.isEmployee
                ? _lookupFromName(user.watchedUnitId, user.watchedUnitName)
                : null,
            watchedNeighborhood: user.isEmployee
                ? _lookupFromName(
                    user.watchedNeighborhoodId,
                    user.watchedNeighborhoodName,
                  )
                : null,
            watchedZone: user.isEmployee
                ? _lookupFromName(user.watchedZoneId, user.watchedZoneName)
                : null,
            clearDefaultLocation: true,
            clearWatchedLocation: true,
          ),
        );

        add(LoadUserLocationsEvent());
        add(GetRegionsEvent());
      },
    );
  }

  void _onLoadUserLocations(
    LoadUserLocationsEvent event,
    Emitter<EditProfileState> emit,
  ) {
    final user = state.user;
    if (user == null) return;

    // Default locations — use effective fields (default > watched fallback)
    LocationLookupEntity? defReg, defUnit, defNh, defZone;
    defReg = _lookupFromName(user.effectiveRegionId, user.effectiveRegionName);
    if (defReg != null) {
      defUnit = _lookupFromName(user.effectiveUnitId, user.effectiveUnitName);
      defNh = _lookupFromName(
        user.effectiveNeighborhoodId,
        user.effectiveNeighborhoodName,
      );
      defZone = _lookupFromName(user.effectiveZoneId, user.effectiveZoneName);
    }

    // Watched locations (employee) — check by name, not ID
    LocationLookupEntity? watchReg, watchUnit, watchNh, watchZone;
    watchReg = _lookupFromName(user.watchedRegionId, user.watchedRegionName);
    if (watchReg != null) {
      watchUnit = _lookupFromName(user.watchedUnitId, user.watchedUnitName);
      watchNh = _lookupFromName(
        user.watchedNeighborhoodId,
        user.watchedNeighborhoodName,
      );
      watchZone = _lookupFromName(user.watchedZoneId, user.watchedZoneName);
    }

    emit(
      state.copyWith(
        defaultRegion: defReg,
        defaultUnit: defUnit,
        defaultNeighborhood: defNh,
        defaultZone: defZone,
        watchedRegion: watchReg,
        watchedUnit: watchUnit,
        watchedNeighborhood: watchNh,
        watchedZone: watchZone,
        clearDefaultLocation: true,
        clearWatchedLocation: true,
        selectedRegion: user.isEmployee ? watchReg : defReg,
        selectedUnit: user.isEmployee ? watchUnit : defUnit,
        selectedNeighborhood: user.isEmployee ? watchNh : defNh,
        selectedZone: user.isEmployee ? watchZone : defZone,
        // Also sync IDs so the cascade in _onGetRegions can trigger
        selectedRegionId: user.isEmployee
            ? (user.watchedRegionId > 0 ? user.watchedRegionId : null)
            : (user.effectiveRegionId > 0 ? user.effectiveRegionId : null),
        selectedUnitId: user.isEmployee
            ? (user.watchedUnitId > 0 ? user.watchedUnitId : null)
            : (user.effectiveUnitId > 0 ? user.effectiveUnitId : null),
        selectedNeighborhoodId: user.isEmployee
            ? (user.watchedNeighborhoodId > 0
                  ? user.watchedNeighborhoodId
                  : null)
            : (user.effectiveNeighborhoodId > 0
                  ? user.effectiveNeighborhoodId
                  : null),
        selectedZoneId: user.isEmployee
            ? (user.watchedZoneId > 0 ? user.watchedZoneId : null)
            : (user.effectiveZoneId > 0 ? user.effectiveZoneId : null),
      ),
    );
  }

  Future<void> _onGetRegions(
    GetRegionsEvent event,
    Emitter<EditProfileState> emit,
  ) async {
    emit(state.copyWith(isRegionsLoading: true));
    final result = await _getRegions();
    result.fold(
      (f) => emit(
        state.copyWith(isRegionsLoading: false, errorMessage: f.errMessage),
      ),
      (list) {
        emit(state.copyWith(isRegionsLoading: false, regions: list));

        if (list.length == 1 && state.selectedRegion == null) {
          add(
            LocationSelectionChanged(
              fieldType: 'region',
              value: list.first,
              isDefaultLocation: true,
              fromSavedLocation: true,
            ),
          );
          return;
        }

        // Cascade: trigger if selectedRegionId exists OR if effective region data is available
        // Uses state.defaultRegion (from _onLoadUserLocations) as fallback when ID is 0
        final hasRegionId =
            state.selectedRegionId != null && state.selectedRegionId! > 0;
        final hasDefaultRegion =
            state.defaultRegion != null ||
            (state.user?.effectiveRegionName != null &&
                state.user!.effectiveRegionName!.isNotEmpty);

        if (!hasRegionId && !hasDefaultRegion) return;

        final targetId = hasRegionId
            ? state.selectedRegionId!
            : (state.defaultRegion?.id ?? 0);
        final reg = targetId > 0
            ? list.where((e) => e.id == targetId).firstOrNull
            : (list
                      .where((e) => e.name == state.user?.effectiveRegionName)
                      .firstOrNull ??
                  state.defaultRegion);
        if (reg != null) {
          add(
            LocationSelectionChanged(
              fieldType: 'region',
              value: reg,
              isDefaultLocation: true,
              fromSavedLocation: true,
            ),
          );
        }
      },
    );
  }

  void _onResetLocationSelection(
    ResetLocationSelectionEvent event,
    Emitter<EditProfileState> emit,
  ) {
    emit(state.copyWith(resetLocationSelection: true, clearError: true));
    if (state.regions.length == 1) {
      add(
        LocationSelectionChanged(
          fieldType: 'region',
          value: state.regions.first,
          isDefaultLocation: true,
        ),
      );
    }
  }

  Future<void> _onLocationChanged(
    LocationSelectionChanged event,
    Emitter<EditProfileState> emit,
  ) async {
    final val = event.value;
    final shouldResetChildren = !event.fromSavedLocation;

    if (event.fieldType == 'region') {
      // Guard: ignore re-selection of the same region unless loading saved location.
      if (!event.fromSavedLocation && state.selectedRegionId == val.id) return;

      emit(
        state.copyWith(
          selectedRegion: val,
          selectedRegionId: val.id,
          resetUnits: shouldResetChildren,
          resetNeighborhoods: shouldResetChildren,
          resetZones: shouldResetChildren,
          isUnitsLoading: true,
        ),
      );

      final res = await _getUnits(val.id);
      res.fold(
        (f) => emit(
          state.copyWith(isUnitsLoading: false, errorMessage: f.errMessage),
        ),
        (list) {
          emit(state.copyWith(isUnitsLoading: false, units: list));
          if (list.length == 1) {
            add(
              LocationSelectionChanged(
                fieldType: 'unit',
                value: list.first,
                isDefaultLocation: true,
                fromSavedLocation: event.fromSavedLocation,
              ),
            );
            return;
          }
          if (event.fromSavedLocation &&
              state.selectedUnitId != null &&
              state.selectedUnitId! > 0) {
            final unit = list
                .where((e) => e.id == state.selectedUnitId)
                .firstOrNull;
            if (unit != null) {
              add(
                LocationSelectionChanged(
                  fieldType: 'unit',
                  value: unit,
                  isDefaultLocation: true,
                  fromSavedLocation: true,
                ),
              );
            }
          }
        },
      );
    } else if (event.fieldType == 'unit') {
      // Guard: ignore re-selection of the same unit unless loading saved location.
      if (!event.fromSavedLocation && state.selectedUnitId == val.id) return;

      emit(
        state.copyWith(
          selectedUnit: val,
          selectedUnitId: val.id,
          resetNeighborhoods: shouldResetChildren,
          resetZones: shouldResetChildren,
          isNeighborhoodsLoading: true,
        ),
      );

      // Scoped to the chosen unit: the tree knows which neighborhoods belong
      // to it, so the picker no longer lists the whole region's.
      final res = await _getNeighborhoods(val.id);
      res.fold(
        (f) => emit(
          state.copyWith(
            isNeighborhoodsLoading: false,
            errorMessage: f.errMessage,
          ),
        ),
        (list) {
          emit(
            state.copyWith(isNeighborhoodsLoading: false, neighborhoods: list),
          );
          if (list.length == 1) {
            add(
              LocationSelectionChanged(
                fieldType: 'neighborhood',
                value: list.first,
                isDefaultLocation: true,
                fromSavedLocation: event.fromSavedLocation,
              ),
            );
            return;
          }
          if (event.fromSavedLocation &&
              state.selectedNeighborhoodId != null &&
              state.selectedNeighborhoodId! > 0) {
            final nh = list
                .where((e) => e.id == state.selectedNeighborhoodId)
                .firstOrNull;
            if (nh != null) {
              add(
                LocationSelectionChanged(
                  fieldType: 'neighborhood',
                  value: nh,
                  isDefaultLocation: true,
                  fromSavedLocation: true,
                ),
              );
            }
          }
        },
      );
    } else if (event.fieldType == 'neighborhood') {
      // Guard: ignore re-selection of the same neighborhood unless loading saved location.
      if (!event.fromSavedLocation && state.selectedNeighborhoodId == val.id)
        return;

      emit(
        state.copyWith(
          selectedNeighborhood: val,
          selectedNeighborhoodId: val.id,
          resetZones: shouldResetChildren,
          isZonesLoading: true,
        ),
      );

      // Scoped to the chosen neighborhood, for the same reason.
      final res = await _getZones(val.id);
      res.fold(
        (f) => emit(
          state.copyWith(isZonesLoading: false, errorMessage: f.errMessage),
        ),
        (list) {
          emit(state.copyWith(isZonesLoading: false, zones: list));
          if (list.length == 1) {
            add(
              LocationSelectionChanged(
                fieldType: 'zone',
                value: list.first,
                isDefaultLocation: true,
                fromSavedLocation: event.fromSavedLocation,
              ),
            );
            return;
          }
          if (event.fromSavedLocation &&
              state.selectedZoneId != null &&
              state.selectedZoneId! > 0) {
            final zone = list
                .where((e) => e.id == state.selectedZoneId)
                .firstOrNull;
            if (zone != null) {
              add(
                LocationSelectionChanged(
                  fieldType: 'zone',
                  value: zone,
                  isDefaultLocation: true,
                  fromSavedLocation: true,
                ),
              );
            }
          }
        },
      );
    } else if (event.fieldType == 'zone') {
      // Guard: ignore re-selection of the same zone unless loading saved location.
      if (!event.fromSavedLocation && state.selectedZoneId == val.id) return;

      emit(state.copyWith(selectedZone: val, selectedZoneId: val.id));
    }
  }

  void _onNameChanged(NameChangedEvent event, Emitter<EditProfileState> emit) {
    emit(state.copyWith(fullName: event.name.trim()));
  }

  static bool _sameId(int? a, int b) => (a ?? 0) == b;

  Future<void> _onSubmitProfile(
    SubmitProfileEvent event,
    Emitter<EditProfileState> emit,
  ) async {
    if (state.fullName.trim().isEmpty ||
        (state.isCitizen &&
            (state.selectedZoneId == null || state.selectedZoneId == 0))) {
      emit(state.copyWith(errorMessage: 'completeRequiredFields'));
      return;
    }

    // Guard: if nothing actually changed, skip the API call and report success.
    final user = state.user;
    if (user != null &&
        state.fullName.trim() == user.fullName.trim() &&
        _sameId(
          state.selectedRegionId,
          user.isCitizen ? user.defaultRegionId : user.watchedRegionId,
        ) &&
        _sameId(
          state.selectedUnitId,
          user.isCitizen ? user.defaultUnitId : user.watchedUnitId,
        ) &&
        _sameId(
          state.selectedNeighborhoodId,
          user.isCitizen
              ? user.defaultNeighborhoodId
              : user.watchedNeighborhoodId,
        ) &&
        _sameId(
          state.selectedZoneId,
          user.isCitizen ? user.defaultZoneId : user.watchedZoneId,
        )) {
      emit(state.copyWith(isSuccess: true));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    final params = UpdateProfileParams(
      fullName: state.fullName.trim(),
      regionId: state.selectedRegionId ?? 0,
      unitId: state.selectedUnitId ?? 0,
      neighborhoodId: state.selectedNeighborhoodId ?? 0,
      zoneId: state.selectedZoneId ?? 0,
    );

    final result = await _updateProfile(params);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.errMessage)),
      (user) {
        ProfileEventBus.instance.notifyProfileUpdated();

        emit(
          state.copyWith(
            isLoading: false,
            isSuccess: true,
            user: user,
            fullName: user.fullName,
            shouldNavigateToNavbar: event.isCompleteProfile,
          ),
        );
        add(LoadUserLocationsEvent());
        if (event.isCompleteProfile) {
          add(const NavigateAfterCompleteEvent());
        }
      },
    );
  }

  Future<void> _onNavigateAfterComplete(
    NavigateAfterCompleteEvent event,
    Emitter<EditProfileState> emit,
  ) async {
    emit(state.copyWith(shouldNavigateToNavbar: true));
  }

  void _onResetForm(ResetFormEvent event, Emitter<EditProfileState> emit) {
    emit(state.copyWith(clearSuccess: true, clearError: true));
  }

  void _onApplySavedLocationSelection(
    ApplySavedLocationSelection event,
    Emitter<EditProfileState> emit,
  ) {
    emit(
      state.copyWith(
        selectedRegionId: event.regionId,
        selectedUnitId: event.unitId,
        selectedNeighborhoodId: event.neighborhoodId,
        selectedZoneId: event.zoneId,
        resetUnits: true,
        resetNeighborhoods: true,
        resetZones: true,
        clearError: true,
      ),
    );

    if (state.regions.isEmpty) {
      add(GetRegionsEvent());
      return;
    }

    final region = state.regions
        .where((e) => e.id == event.regionId)
        .firstOrNull;
    if (region != null) {
      add(
        LocationSelectionChanged(
          fieldType: 'region',
          value: region,
          isDefaultLocation: true,
          fromSavedLocation: true,
        ),
      );
    }
  }
}

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/notification/notification_service.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/employee/domain/repositories/i_employee_repository.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_event.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';
import 'package:qatrah/features/profile/domain/repositories/i_hierarchy_repository.dart';

/// Case-insensitive keyword match over the operator-visible text of a
/// schedule: notes, pause/cancellation reasons and location names.
bool scheduleMatchesQuery(ScheduleEntity schedule, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return [
    schedule.notes,
    schedule.cancellationReason,
    schedule.pauseReason,
    schedule.regionName,
    schedule.unitName,
    schedule.neighborhoodName,
    schedule.zoneName,
    schedule.fullLocationPath,
  ].nonNulls.any((field) => field.toLowerCase().contains(needle));
}

/// Whether a schedule starts inside the picked day range. The date pickers
/// hand back midnight, so both bounds are widened to whole days — a schedule
/// on the "to" day itself stays in range.
bool scheduleInDateRange(
  ScheduleEntity schedule,
  DateTime? from,
  DateTime? to,
) {
  if (from != null) {
    final start = DateTime(from.year, from.month, from.day);
    if (schedule.startTime.isBefore(start)) return false;
  }
  if (to != null) {
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    if (schedule.startTime.isAfter(end)) return false;
  }
  return true;
}

/// Push `type`s that mean a schedule's pumping state changed server-side.
const pumpingChangeTypes = {
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
  'SCHEDULE_SHIFTED',
  'PUMPING_SHIFTED',
};

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._repository, this._hierarchyRepository)
    : super(const DashboardState()) {
    _notificationSubscription = NotificationService.instance.notificationStream
        .listen(
          _onPushNotification,
        );

    on<LoadDashboardData>(_onLoadData);
    on<FilterRegionChanged>(_onFilterRegion);
    on<FilterUnitChanged>(_onFilterUnit);
    on<FilterNeighborhoodChanged>(_onFilterNeighborhood);
    on<FilterZoneChanged>(_onFilterZone);
    on<FilterStatusChanged>(_onFilterStatus);
    on<FilterFromDateChanged>(_onFromDateChanged);
    on<FilterToDateChanged>(_onToDateChanged);
    on<FilterSearchChanged>(_onFilterSearch);
    on<ResetFilters>(_onResetFilters);
    on<StartScheduleEvent>(_onStartSchedule);
    on<EndScheduleEvent>(_onEndSchedule);
    on<PauseScheduleEvent>(_onPauseSchedule);
    on<ResumeScheduleEvent>(_onResumeSchedule);
    on<CancelScheduleEvent>(_onCancelSchedule);
    on<ShiftScheduleEvent>(_onShiftSchedule);
    on<CreateScheduleSubmitted>(_onCreateSchedule);
    on<UpdateScheduleSubmitted>(_onUpdateSchedule);
    on<FetchUnitsEvent>(_onFetchUnits);
    on<FetchNeighborhoodsEvent>(_onFetchNeighborhoods);
    on<FetchZonesEvent>(_onFetchZones);
    on<ResetHierarchyEvent>(_onResetHierarchy);
    on<RefreshSchedulesEvent>(_onRefreshSchedules);
    on<PushNotificationReceivedEvent>(_onPushNotificationReceived);
  }
  final IDashboardRepository _repository;
  final IHierarchyRepository _hierarchyRepository;
  StreamSubscription<RemoteMessage>? _notificationSubscription;

  void _onPushNotification(RemoteMessage message) {
    final type = (message.data['type'] ?? '').toString().toUpperCase();
    if (pumpingChangeTypes.contains(type)) {
      final scheduleId = int.tryParse(
        message.data['scheduleId']?.toString() ?? '',
      );
      add(PushNotificationReceivedEvent(type: type, scheduleId: scheduleId));
    }
  }

  Future<void> _onPushNotificationReceived(
    PushNotificationReceivedEvent event,
    Emitter<DashboardState> emit,
  ) async {
    add(LoadDashboardData());
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, isSuccess: false));
    final regionsRes = await _repository.getActiveRegions();
    final selectedStatus =
        state.selectedStatus != null && state.selectedStatus != 'ALL'
        ? state.selectedStatus
        : null;

    // Sorting strategy:
    //  • No specific status (initial load): omit `sort` so the backend applies
    //    its priority-based ordering across the WHOLE dataset at the DB level
    //    (ACTIVE → PAUSED → SCHEDULED → COMPLETED → CANCELLED, then startTime
    //    ascending). Sending an explicit `sort` here would override that and
    //    only sort per-page due to pagination.
    //  • COMPLETED: most recently completed first.
    //  • Any other specific status: closest startTime first (secondary rule).
    final sort = switch (selectedStatus?.toUpperCase()) {
      null => null,
      'COMPLETED' => 'actualEndTime,desc',
      _ => 'startTime,asc',
    };

    final schedulesRes = await _repository.getSchedules(
      zoneId: state.selectedZone?.id,
      status: selectedStatus,
      sort: sort,
    );

    regionsRes.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.errMessage)),
      (regionsList) {
        schedulesRes.fold(
          (f) => emit(
            state.copyWith(isLoading: false, errorMessage: f.errMessage),
          ),
          (schedulesList) {
            final newState = state.copyWith(
              isLoading: false,
              regions: regionsList,
              allSchedules: schedulesList,
            );
            emit(_applyFiltersLocally(newState));
          },
        );
      },
    );
  }

  DashboardState _applyFiltersLocally(DashboardState currentState) {
    var filtered = currentState.allSchedules;

    if (currentState.selectedRegion != null) {
      filtered = filtered
          .where((s) => s.regionName == currentState.selectedRegion!.name)
          .toList();
    }

    if (currentState.selectedUnit != null) {
      filtered = filtered
          .where((s) => s.unitName == currentState.selectedUnit!.name)
          .toList();
    }

    if (currentState.selectedNeighborhood != null) {
      filtered = filtered
          .where(
            (s) =>
                s.neighborhoodName == currentState.selectedNeighborhood!.name,
          )
          .toList();
    }

    if (currentState.selectedZone != null) {
      filtered = filtered
          .where((s) => s.zoneName == currentState.selectedZone!.name)
          .toList();
    }

    if (currentState.selectedStatus != null &&
        currentState.selectedStatus != 'ALL') {
      filtered = filtered
          .where(
            (s) =>
                s.status.toUpperCase() ==
                currentState.selectedStatus!.toUpperCase(),
          )
          .toList();
    }

    if (currentState.fromDate != null || currentState.toDate != null) {
      filtered = filtered
          .where(
            (s) => scheduleInDateRange(
              s,
              currentState.fromDate,
              currentState.toDate,
            ),
          )
          .toList();
    }

    if (currentState.searchQuery.trim().isNotEmpty) {
      filtered = filtered
          .where((s) => scheduleMatchesQuery(s, currentState.searchQuery))
          .toList();
    }

    return currentState.copyWith(filteredSchedules: filtered);
  }

  Future<void> _onFilterRegion(
    FilterRegionChanged event,
    Emitter<DashboardState> emit,
  ) async {
    // Guard: ignore re-selection of the same region.
    if (state.selectedRegion?.id == event.region?.id) return;

    var newState = state.copyWith(
      selectedRegion: event.region,
      filterUnits: [],
      filterNeighborhoods: [],
      filterZones: [],
    );

    if (event.region != null) {
      emit(newState.copyWith(isFilterUnitsLoading: true));
      final unitsRes = await _hierarchyRepository.getUnits(event.region!.id);
      unitsRes.fold(
        (f) => emit(
          state.copyWith(
            isFilterUnitsLoading: false,
            errorMessage: f.errMessage,
          ),
        ),
        (list) {
          newState = newState.copyWith(
            isFilterUnitsLoading: false,
            filterUnits: list,
          );
          emit(_applyFiltersLocally(newState));
        },
      );
    } else {
      emit(_applyFiltersLocally(newState));
    }
  }

  Future<void> _onFilterUnit(
    FilterUnitChanged event,
    Emitter<DashboardState> emit,
  ) async {
    // Guard: ignore re-selection of the same unit.
    if (state.selectedUnit?.id == event.unit?.id) return;

    var newState = state.copyWith(
      selectedUnit: event.unit,
      filterNeighborhoods: [],
      filterZones: [],
    );

    if (event.unit != null && state.selectedRegion != null) {
      emit(newState.copyWith(isFilterNeighborhoodsLoading: true));
      // Pass regionId, not unitId -- API uses region/{id} for neighborhoods
      final neighborhoodsRes = await _hierarchyRepository.getNeighborhoods(
        state.selectedRegion!.id,
      );
      neighborhoodsRes.fold(
        (f) => emit(
          state.copyWith(
            isFilterNeighborhoodsLoading: false,
            errorMessage: f.errMessage,
          ),
        ),
        (list) {
          newState = newState.copyWith(
            isFilterNeighborhoodsLoading: false,
            filterNeighborhoods: list,
          );
          emit(_applyFiltersLocally(newState));
        },
      );
    } else {
      emit(_applyFiltersLocally(newState));
    }
  }

  Future<void> _onFilterNeighborhood(
    FilterNeighborhoodChanged event,
    Emitter<DashboardState> emit,
  ) async {
    // Guard: ignore re-selection of the same neighborhood.
    if (state.selectedNeighborhood?.id == event.neighborhood?.id) return;

    var newState = state.copyWith(
      selectedNeighborhood: event.neighborhood,
      filterZones: [],
    );

    // Fetch zones when a neighborhood is selected
    if (event.neighborhood != null && state.selectedRegion != null) {
      emit(newState.copyWith(isFilterZonesLoading: true));
      final zonesRes = await _hierarchyRepository.getZones(
        state.selectedRegion!.id,
      );
      zonesRes.fold(
        (f) => emit(
          state.copyWith(
            isFilterZonesLoading: false,
            errorMessage: f.errMessage,
          ),
        ),
        (list) {
          newState = newState.copyWith(
            isFilterZonesLoading: false,
            filterZones: list,
          );
          emit(_applyFiltersLocally(newState));
        },
      );
    } else {
      emit(_applyFiltersLocally(newState));
    }
  }

  void _onFilterZone(FilterZoneChanged event, Emitter<DashboardState> emit) {
    // Guard: ignore re-selection of the same zone.
    if (state.selectedZone?.id == event.zone?.id) return;

    final newState = state.copyWith(selectedZone: event.zone);
    emit(_applyFiltersLocally(newState));
  }

  void _onFilterStatus(
    FilterStatusChanged event,
    Emitter<DashboardState> emit,
  ) {
    final newState = state.copyWith(selectedStatus: event.status);
    emit(_applyFiltersLocally(newState));
  }

  void _onFromDateChanged(
    FilterFromDateChanged event,
    Emitter<DashboardState> emit,
  ) {
    final newState = state.copyWith(fromDate: event.date);
    emit(_applyFiltersLocally(newState));
  }

  void _onToDateChanged(
    FilterToDateChanged event,
    Emitter<DashboardState> emit,
  ) {
    final newState = state.copyWith(toDate: event.date);
    emit(_applyFiltersLocally(newState));
  }

  void _onFilterSearch(
    FilterSearchChanged event,
    Emitter<DashboardState> emit,
  ) {
    if (event.query == state.searchQuery) return;
    emit(_applyFiltersLocally(state.copyWith(searchQuery: event.query)));
  }

  Future<void> _onResetFilters(
    ResetFilters event,
    Emitter<DashboardState> emit,
  ) async {
    final newState = state.copyWith(clearFilters: true);
    emit(_applyFiltersLocally(newState));
  }

  Future<void> _onStartSchedule(
    StartScheduleEvent event,
    Emitter<DashboardState> emit,
  ) async {
    // Defensive client-side guard: do not allow starting a schedule before its
    // scheduled start time. The backend is the source of truth and rejects this
    // too (error code START_TIME_IN_FUTURE), but blocking here avoids a wasted
    // round-trip and surfaces the localized message immediately.
    final matches = state.allSchedules.where((s) => s.id == event.id);
    final schedule = matches.isEmpty ? null : matches.first;
    if (schedule != null && DateTime.now().isBefore(schedule.startTime)) {
      emit(state.copyWith(errorMessage: 'cannotStartBeforeScheduledTime'));
      return;
    }

    final res = await _repository.startSchedule(event.id);
    res.fold(
      (f) => emit(state.copyWith(errorMessage: f.errMessage)),
      (_) {
        final updated = state.allSchedules
            .map((s) => s.id == event.id ? s.copyWith(status: 'ACTIVE') : s)
            .toList();
        emit(_applyFiltersLocally(state.copyWith(allSchedules: updated)));
        add(LoadDashboardData());
      },
    );
  }

  Future<void> _onEndSchedule(
    EndScheduleEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final res = await _repository.endSchedule(event.id);
    res.fold(
      (f) => emit(state.copyWith(errorMessage: f.errMessage)),
      (_) {
        final updated = state.allSchedules
            .map((s) => s.id == event.id ? s.copyWith(status: 'COMPLETED') : s)
            .toList();
        emit(_applyFiltersLocally(state.copyWith(allSchedules: updated)));
        add(LoadDashboardData());
      },
    );
  }

  Future<void> _onPauseSchedule(
    PauseScheduleEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final res = await _repository.pauseSchedule(
      event.id,
      pauseReason: event.pauseReason,
    );
    res.fold(
      (f) => emit(state.copyWith(errorMessage: f.errMessage)),
      (_) {
        final updated = state.allSchedules
            .map(
              (s) => s.id == event.id
                  ? s.copyWith(
                      status: 'PAUSED',
                      temporaryFailure: true,
                      pauseReason: event.pauseReason,
                    )
                  : s,
            )
            .toList();
        emit(_applyFiltersLocally(state.copyWith(allSchedules: updated)));
        add(LoadDashboardData());
      },
    );
  }

  Future<void> _onResumeSchedule(
    ResumeScheduleEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final res = await _repository.resumeSchedule(event.id);
    res.fold(
      (f) => emit(state.copyWith(errorMessage: f.errMessage)),
      (_) {
        final updated = state.allSchedules
            .map(
              (s) => s.id == event.id
                  ? s.copyWith(
                      status: 'ACTIVE',
                      temporaryFailure: false,
                    )
                  : s,
            )
            .toList();
        emit(_applyFiltersLocally(state.copyWith(allSchedules: updated)));
        add(LoadDashboardData());
      },
    );
  }

  Future<void> _onCancelSchedule(
    CancelScheduleEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final res = await _repository.cancelSchedule(
      event.id,
      cancellationReason: event.cancellationReason,
    );
    res.fold(
      (f) => emit(state.copyWith(errorMessage: f.errMessage)),
      (_) {
        final updated = state.allSchedules
            .map(
              (s) => s.id == event.id
                  ? s.copyWith(
                      status: 'CANCELLED',
                      cancellationReason: event.cancellationReason,
                    )
                  : s,
            )
            .toList();
        emit(_applyFiltersLocally(state.copyWith(allSchedules: updated)));
        add(LoadDashboardData());
      },
    );
  }

  Future<void> _onShiftSchedule(
    ShiftScheduleEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (event.hours <= 0) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: 'errorShiftingSchedule',
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, isSuccess: false));
    final res = await _repository.shiftSchedule(
      event.id,
      hours: event.hours,
      postponeReason: event.postponeReason,
    );
    res.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.errMessage)),
      (_) {
        // Optimistically shift the start/end times so the table updates
        // immediately; the subsequent reload reconciles with the backend.
        final delay = Duration(hours: event.hours);
        final updated = state.allSchedules
            .map(
              (s) => s.id == event.id
                  ? s.copyWith(
                      startTime: s.startTime.add(delay),
                      endTime: s.endTime.add(delay),
                    )
                  : s,
            )
            .toList();
        emit(
          _applyFiltersLocally(
            state.copyWith(
              isLoading: false,
              isSuccess: true,
              allSchedules: updated,
            ),
          ),
        );
        add(LoadDashboardData());
      },
    );
  }

  Future<void> _onCreateSchedule(
    CreateScheduleSubmitted event,
    Emitter<DashboardState> emit,
  ) async {
    // ponytail: 1-min grace so "start now" isn't rejected by clock drift between
    // picker selection and submit. Backend remains authoritative on START_TIME.
    final now = DateTime.now().subtract(const Duration(minutes: 1));

    // Start time must be now (within grace) or later
    if (event.start.isBefore(now)) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: 'startDateMustBeInFuture',
        ),
      );
      return;
    }

    // End time must be strictly after start time
    if (!event.end.isAfter(event.start)) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: 'endDateMustBeAfterStart',
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, isSuccess: false));
    final result = await _repository.createSchedule(
      regionId: event.regionId,
      unitId: event.unitId,
      neighborhoodId: event.neighborhoodId,
      zoneId: event.zoneId,
      start: event.start,
      end: event.end,
      notes: event.notes,
    );
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.errMessage)),
      (_) {
        emit(state.copyWith(isLoading: false, isSuccess: true));
        add(LoadDashboardData());
      },
    );
  }

  Future<void> _onUpdateSchedule(
    UpdateScheduleSubmitted event,
    Emitter<DashboardState> emit,
  ) async {
    // ponytail: same 1-min grace as create (see _onCreateSchedule).
    final now = DateTime.now().subtract(const Duration(minutes: 1));

    if (event.start.isBefore(now)) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: 'startDateMustBeInFuture',
        ),
      );
      return;
    }

    if (!event.end.isAfter(event.start)) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: 'endDateMustBeAfterStart',
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, isSuccess: false));
    final result = await _repository.updateSchedule(
      scheduleId: event.scheduleId,
      regionId: event.regionId,
      unitId: event.unitId,
      neighborhoodId: event.neighborhoodId,
      zoneId: event.zoneId,
      start: event.start,
      end: event.end,
      notes: event.notes,
    );
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.errMessage)),
      (_) {
        emit(state.copyWith(isLoading: false, isSuccess: true));
        add(LoadDashboardData());
      },
    );
  }

  Future<void> _onFetchUnits(
    FetchUnitsEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        isUnitsLoading: true,
        units: [],
        neighborhoods: [],
        zones: [],
      ),
    );
    final result = await _hierarchyRepository.getUnits(event.regionId);
    result.fold(
      (f) => emit(
        state.copyWith(isUnitsLoading: false, errorMessage: f.errMessage),
      ),
      (list) => emit(state.copyWith(isUnitsLoading: false, units: list)),
    );
  }

  Future<void> _onFetchNeighborhoods(
    FetchNeighborhoodsEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        isNeighborhoodsLoading: true,
        neighborhoods: [],
        zones: [],
      ),
    );
    final result = await _hierarchyRepository.getNeighborhoods(event.regionId);
    result.fold(
      (f) => emit(
        state.copyWith(
          isNeighborhoodsLoading: false,
          errorMessage: f.errMessage,
        ),
      ),
      (list) => emit(
        state.copyWith(isNeighborhoodsLoading: false, neighborhoods: list),
      ),
    );
  }

  Future<void> _onFetchZones(
    FetchZonesEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isZonesLoading: true, zones: []));
    final result = await _hierarchyRepository.getZones(event.regionId);
    result.fold(
      (f) => emit(
        state.copyWith(isZonesLoading: false, errorMessage: f.errMessage),
      ),
      (list) => emit(state.copyWith(isZonesLoading: false, zones: list)),
    );
  }

  void _onResetHierarchy(
    ResetHierarchyEvent event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(units: [], neighborhoods: [], zones: []));
  }

  Future<void> _onRefreshSchedules(
    RefreshSchedulesEvent event,
    Emitter<DashboardState> emit,
  ) async {
    add(LoadDashboardData());
  }
}

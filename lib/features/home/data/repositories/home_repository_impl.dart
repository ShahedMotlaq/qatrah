import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/app_error_messages.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/utils/pagination.dart';
import 'package:qatrah/features/home/data/models/area_model.dart';
import 'package:qatrah/features/home/data/models/pumping_status_model.dart';
import 'package:qatrah/features/home/data/models/schedule_model.dart';
import 'package:qatrah/features/home/domain/entities/area_entity.dart';
import 'package:qatrah/features/home/domain/entities/pumping_status_entity.dart';
import 'package:qatrah/features/home/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/home/domain/repositories/i_home_repository.dart';
import 'package:qatrah/features/profile/domain/repositories/i_hierarchy_repository.dart';

class HomeRepositoryImpl implements IHomeRepository {
  HomeRepositoryImpl(this._apiService, this._hierarchyRepository);
  final ApiService _apiService;

  /// Areas are the location tree seen flat, so they come from the same
  /// session cache the pickers use instead of a second /hierarchy/flat call.
  final IHierarchyRepository _hierarchyRepository;

  /// In-memory pumping-status cache for non-default addresses, keyed by zone
  /// (or neighbourhood). Lets the user switch back to a recently-viewed
  /// address without refetching. The default home is never cached here — it
  /// always hits the live `/schedules/home-status` endpoint.
  final Map<String, _CachedPumpingStatus> _pumpingStatusCache = {};
  static const Duration _pumpingStatusCacheTtl = Duration(minutes: 5);

  @override
  void clearPumpingStatusCache() => _pumpingStatusCache.clear();

  // ===========================================================================
  // Helpers — endpoint selection + response parsing
  // ===========================================================================

  bool _shouldUseRegionDateRange({
    int? regionId,
    int? neighborhoodId,
    int? zoneId,
    List<int>? unitIds,
  }) {
    return regionId != null &&
        neighborhoodId == null &&
        zoneId == null &&
        !(unitIds != null && unitIds.isNotEmpty);
  }

  /// Fetches ALL schedules for a neighbourhood using the dedicated endpoint.
  ///
  /// This is the preferred path when a `neighborhoodId` is known — it avoids
  /// fetching a large paginated set and then filtering on the client.
  Future<List<ScheduleEntity>> _fetchNeighborhoodSchedules(
    int neighborhoodId,
  ) async {
    final dynamic response = await _apiService.get(
      endPoint: ApiEndpoints.schedulesByNeighborhood(neighborhoodId),
    );
    final data = _extractList(response);
    return data
        .map((e) => ScheduleModelMapper.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<dynamic> _fetchPublicSchedules({
    int page = 0,
    int size = 10,
    int? regionId,
    int? neighborhoodId,
    int? zoneId,
    List<int>? unitIds,
  }) async {
    var endPoint = ApiEndpoints.schedulesPublic;
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
      'neighborhoodId': ?neighborhoodId,
      'zoneId': ?zoneId,
      if (unitIds != null && unitIds.isNotEmpty) 'unitIds': unitIds.join(','),
    };

    if (_shouldUseRegionDateRange(
      regionId: regionId,
      neighborhoodId: neighborhoodId,
      zoneId: zoneId,
      unitIds: unitIds,
    )) {
      endPoint = ApiEndpoints.schedulesPublicRegionDateRange(regionId!);
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final threeDaysLater = now.add(const Duration(days: 3));
      queryParameters
        ..remove('page')
        ..remove('size')
        ..['start'] = startOfDay.toIso8601String()
        ..['end'] = threeDaysLater.toIso8601String();
    }

    return _apiService.get(
      endPoint: endPoint,
      queryParameters: queryParameters,
    );
  }

  Pagination<ScheduleEntity> _parseSchedulesPagination(
    dynamic response, {
    required bool usedRegionDateRange,
  }) {
    if (usedRegionDateRange ||
        response is List ||
        (response is Map &&
            response['data'] is List &&
            response['content'] == null)) {
      final data = _extractList(response);
      final list = data
          .map((e) => ScheduleModelMapper.fromJson(e as Map<String, dynamic>))
          .toList();

      return Pagination<ScheduleEntity>(
        content: list,
        currentPage: 0,
        pageSize: list.length,
        totalElements: list.length,
        totalPages: 1,
        isLast: true,
        isFirst: true,
        isEmpty: list.isEmpty,
      );
    }

    return Pagination.fromJson(
      response as Map<String, dynamic>,
      ScheduleModelMapper.fromJson,
    );
  }

  Map<String, dynamic> _extractHomeStatusPayload(
    Map<String, dynamic> response,
  ) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }

  PumpingStatusEntity? _parseHomeStatusItem(
    dynamic raw, {
    required PumpingStatus status,
  }) {
    if (raw is! Map<String, dynamic>) return null;
    final expectedStatus = status.name.toUpperCase();
    final rawStatus = (raw['status'] as String? ?? '').toUpperCase();
    final isTemporaryFailure = raw['temporaryFailure'] == true;
    final shouldUseExpectedStatus =
        rawStatus.isEmpty ||
        (status == PumpingStatus.paused && isTemporaryFailure);
    if (!shouldUseExpectedStatus && rawStatus != expectedStatus) return null;
    return PumpingStatusModelMapper.fromJson({
      ...raw,
      if (shouldUseExpectedStatus) 'status': expectedStatus,
    });
  }

  List<PumpingStatusEntity> _parseHomeStatusResponse(
    Map<String, dynamic> response,
  ) {
    final payload = _extractHomeStatusPayload(response);

    final active = _parseHomeStatusItem(
      payload['activeSchedule'],
      status: PumpingStatus.active,
    );
    final paused = _parseHomeStatusItem(
      payload['pausedSchedule'],
      status: PumpingStatus.paused,
    );
    final cancelled = _parseHomeStatusItem(
      payload['recentCancelled'],
      status: PumpingStatus.cancelled,
    );
    final completedRaw = _parseHomeStatusItem(
      payload['lastCompleted'],
      status: PumpingStatus.completed,
    );
    final completed =
        (completedRaw != null && completedRaw.actualEndTime != null)
        ? completedRaw
        : null;
    final scheduled = _parseHomeStatusItem(
      payload['nextScheduled'] ??
          payload['scheduledSchedule'] ??
          payload['upcomingSchedule'],
      status: PumpingStatus.scheduled,
    );

    return <PumpingStatusEntity>[
      ?active,
      ?paused,
      ?cancelled,
      ?completed,
      ?scheduled,
    ];
  }

  List<ScheduleEntity> _filterSchedulesForLocation(
    List<ScheduleEntity> schedules, {
    int? regionId,
    int? neighborhoodId,
    int? zoneId,
  }) {
    return schedules.where((schedule) {
      if (zoneId != null && schedule.zoneId != zoneId) {
        return false;
      }
      if (neighborhoodId != null && schedule.neighborhoodId != neighborhoodId) {
        return false;
      }
      if (zoneId == null &&
          neighborhoodId == null &&
          regionId != null &&
          schedule.regionId != regionId) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Strict "upcoming" check per requirements:
  ///   status == SCHEDULED (or derived SCHEDULED) AND startTime is in the future.
  bool _isUpcomingSchedule(ScheduleEntity schedule) =>
      schedule.currentStatus == ScheduleStatus.scheduled &&
      schedule.startTime.isAfter(DateTime.now());

  // 1. Fetch watched areas
  //
  // ponytail: the tree carries no per-user watch flag, so every area comes
  // back unwatched — same as before, since /hierarchy/flat never sent one
  // either. Real watch state lives in the citizen's saved locations
  // (GET /me/locations); wire that in when the feature is picked up.
  @override
  Future<Either<Failure, List<AreaEntity>>> getWatchedAreas() => getAllAreas();

  // 2. Fetch all areas — the cached tree, depth-first.
  @override
  Future<Either<Failure, List<AreaEntity>>> getAllAreas() async {
    final result = await _hierarchyRepository.getTree();
    return result.map(
      (roots) => [
        for (final root in roots)
          for (final node in root.flatten())
            AreaModelMapper.fromHierarchyNode(node),
      ],
    );
  }

  // 3. Fetch available areas, paged.
  //
  // The location endpoints return plain arrays and are never paginated, so
  // the page and the search are applied here over the cached tree.
  @override
  Future<Either<Failure, Pagination<AreaEntity>>> getAvailableAreas({
    int page = 0,
    int size = 20,
    String? search,
  }) async {
    final result = await getAllAreas();
    return result.map((all) {
      final query = search?.trim().toLowerCase();
      final matches = query == null || query.isEmpty
          ? all
          : all.where((a) => a.name.toLowerCase().contains(query)).toList();

      final start = (page * size).clamp(0, matches.length);
      final end = (start + size).clamp(0, matches.length);
      final totalPages = size <= 0 ? 0 : (matches.length / size).ceil();

      return Pagination<AreaEntity>(
        content: matches.sublist(start, end),
        totalElements: matches.length,
        totalPages: totalPages,
        currentPage: page,
        pageSize: size,
        isFirst: page == 0,
        isLast: end >= matches.length,
        isEmpty: matches.isEmpty,
      );
    });
  }

  // 4. Toggle watch status - Parameters corrected to be Positional
  @override
  Future<Either<Failure, void>> toggleAreaWatch(int areaId, bool watch) async {
    try {
      await _apiService.put(
        endPoint: ApiEndpoints.hierarchyWatch(areaId),
        data: {'watch': watch},
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(AppErrorMessages.fromException(e)));
    }
  }

  // ===========================================================================
  // 5. Fetch pumping status
  //
  // Uses the consolidated backend endpoint `/schedules/home-status`.
  // Backend returns:
  //   - activeSchedule
  //   - recentCancelled
  //   - lastCompleted
  // ===========================================================================
  @override
  Future<Either<Failure, List<PumpingStatusEntity>>> getPumpingStatus({
    int? regionId,
    int? neighborhoodId,
    int? zoneId,
    bool isDefault = true,
  }) async {
    // Default home → consolidated endpoint, scoped server-side to the
    // authenticated user. Never cached: it's the primary, always-fresh view.
    if (isDefault) {
      return _getDefaultHomeStatus(
        regionId: regionId,
        neighborhoodId: neighborhoodId,
        zoneId: zoneId,
      );
    }
    // Any other saved address / monitored area → query its specific zone and
    // assemble the same status shape client-side, behind a short-TTL cache.
    return _getZoneScopedStatus(zoneId: zoneId, neighborhoodId: neighborhoodId);
  }

  Future<Either<Failure, List<PumpingStatusEntity>>> _getDefaultHomeStatus({
    int? regionId,
    int? neighborhoodId,
    int? zoneId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'regionId': ?regionId,
        'neighborhoodId': ?neighborhoodId,
        'zoneId': ?zoneId,
      };
      final response = await _apiService.get(
        endPoint: ApiEndpoints.schedulesHomeStatus,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );
      return Right(_parseHomeStatusResponse(response));
    } catch (e) {
      return Left(ServerFailure(AppErrorMessages.fromException(e)));
    }
  }

  /// Fetches schedules for a specific zone (preferred) or neighbourhood and
  /// builds the same up-to-four-item status list that `/schedules/home-status`
  /// returns. Results are cached per location for [_pumpingStatusCacheTtl].
  Future<Either<Failure, List<PumpingStatusEntity>>> _getZoneScopedStatus({
    int? zoneId,
    int? neighborhoodId,
  }) async {
    final hasZone = zoneId != null && zoneId > 0;
    final hasNeighborhood = neighborhoodId != null && neighborhoodId > 0;

    // Nothing to scope by → fall back to the consolidated endpoint.
    if (!hasZone && !hasNeighborhood) {
      return _getDefaultHomeStatus(
        neighborhoodId: neighborhoodId,
        zoneId: zoneId,
      );
    }

    final cacheKey = hasZone ? 'zone_$zoneId' : 'nh_$neighborhoodId';
    final cached = _pumpingStatusCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _pumpingStatusCacheTtl) {
      return Right(cached.data);
    }

    try {
      final endPoint = hasZone
          ? ApiEndpoints.schedulesByZone(zoneId)
          : ApiEndpoints.schedulesByNeighborhood(neighborhoodId!);
      final dynamic response = await _apiService.get(endPoint: endPoint);
      final schedules = _extractList(response)
          .map(
            (e) => PumpingStatusModelMapper.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      final assembled = _assembleHomeStatus(schedules);
      _pumpingStatusCache[cacheKey] = _CachedPumpingStatus(assembled);
      return Right(assembled);
    } catch (e) {
      return Left(ServerFailure(AppErrorMessages.fromException(e)));
    }
  }

  /// Reduces a raw zone/neighbourhood schedule list to the same shape the
  /// consolidated home-status endpoint returns:
  ///   • live      → first ACTIVE (earliest start); PAUSED only if no ACTIVE
  ///   • cancelled → most recently cancelled
  ///   • completed → most recent COMPLETED whose end time is already in the past
  ///   • scheduled → nearest SCHEDULED whose start time is in the future
  List<PumpingStatusEntity> _assembleHomeStatus(
    List<PumpingStatusEntity> all,
  ) {
    final now = DateTime.now();

    PumpingStatusEntity? earliestStart(Iterable<PumpingStatusEntity> items) {
      PumpingStatusEntity? best;
      for (final s in items) {
        if (best == null || s.startTime.isBefore(best.startTime)) best = s;
      }
      return best;
    }

    // Priority to ACTIVE, then PAUSED.
    final live =
        earliestStart(all.where((s) => s.isActive)) ??
        earliestStart(all.where((s) => s.isPaused));

    PumpingStatusEntity? recentCancelled;
    for (final s in all.where((s) => s.isCancelled)) {
      if (recentCancelled == null ||
          s.startTime.isAfter(recentCancelled.startTime)) {
        recentCancelled = s;
      }
    }

    PumpingStatusEntity? lastCompleted;
    DateTime? lastCompletedEnd;
    for (final s in all.where((s) => s.isCompleted)) {
      final end = s.actualEndTime;
      if (end == null || !end.isBefore(now)) continue;
      if (lastCompletedEnd == null || end.isAfter(lastCompletedEnd)) {
        lastCompleted = s;
        lastCompletedEnd = end;
      }
    }

    PumpingStatusEntity? nextScheduled;
    for (final s in all.where(
      (s) => s.isScheduled && s.startTime.isAfter(now),
    )) {
      if (nextScheduled == null ||
          s.startTime.isBefore(nextScheduled.startTime)) {
        nextScheduled = s;
      }
    }

    return [
      ?live,
      ?recentCancelled,
      ?lastCompleted,
      ?nextScheduled,
    ];
  }

  // ===========================================================================
  // 6. Fetch upcoming schedules
  //
  // Requirement: SCHEDULED status AND startTime > now.
  //
  // When a neighbourhoodId is available the dedicated endpoint returns the
  // complete set in one call; client-side pagination is applied to the result.
  // The generic public endpoint is used as a fallback.
  // ===========================================================================
  @override
  Future<Either<Failure, Pagination<ScheduleEntity>>> getUpcomingSchedules({
    int page = 0,
    int size = 10,
    int? regionId,
    int? neighborhoodId,
    int? zoneId,
    List<int>? unitIds,
  }) async {
    try {
      final List<ScheduleEntity> allSchedules;

      if (neighborhoodId != null) {
        // ── Preferred path: neighbourhood endpoint ──────────────────────
        allSchedules = await _fetchNeighborhoodSchedules(neighborhoodId);
      } else {
        // ── Fallback: generic public endpoint ─────────────────────────
        final usedRegionDateRange = _shouldUseRegionDateRange(
          regionId: regionId,
          zoneId: zoneId,
          unitIds: unitIds,
        );
        final dynamic response = await _fetchPublicSchedules(
          page: page,
          size: size,
          regionId: regionId,
          zoneId: zoneId,
          unitIds: unitIds,
        );
        final pagination = _parseSchedulesPagination(
          response,
          usedRegionDateRange: usedRegionDateRange,
        );
        allSchedules = _filterSchedulesForLocation(
          pagination.content,
          regionId: regionId,
          zoneId: zoneId,
        );
      }

      // Apply the strict upcoming filter: SCHEDULED + startTime in the future.
      final upcoming = allSchedules.where(_isUpcomingSchedule).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      // When using the neighbourhood endpoint we have all data locally;
      // apply pagination manually so the BLoC's load-more logic still works.
      final start = page * size;
      final end = (start + size).clamp(0, upcoming.length);
      final pageContent = start < upcoming.length
          ? upcoming.sublist(start, end)
          : <ScheduleEntity>[];

      return Right(
        Pagination<ScheduleEntity>(
          content: pageContent,
          currentPage: page,
          pageSize: size,
          totalElements: upcoming.length,
          totalPages: upcoming.isEmpty ? 0 : (upcoming.length / size).ceil(),
          isLast: end >= upcoming.length,
          isFirst: page == 0,
          isEmpty: upcoming.isEmpty,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(AppErrorMessages.fromException(e)));
    }
  }

  // 7. Fetch active schedule for feedback - Recently added
  @override
  Future<Either<Failure, PumpingStatusEntity?>>
  getActiveScheduleForFeedback() async {
    try {
      final dynamic response = await _apiService.get(
        endPoint: ApiEndpoints.waterFeedbackActiveScheduleStatus,
      );
      if (response != null &&
          response is Map<String, dynamic> &&
          response['hasActiveSchedule'] == true) {
        return Right(PumpingStatusModelMapper.fromJson(response));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(AppErrorMessages.fromException(e)));
    }
  }

  // 8. Submit water feedback - Recently added
  @override
  Future<Either<Failure, void>> submitWaterFeedback({
    required int scheduleId,
    required String feedbackType,
  }) async {
    try {
      await _apiService.post(
        endPoint: ApiEndpoints.waterFeedback,
        data: {'scheduleId': scheduleId, 'feedbackType': feedbackType},
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(AppErrorMessages.fromException(e)));
    }
  }

  // Helper method to process data lists and prevent casting errors
  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map && response['data'] is List) {
      return response['data'] as List<dynamic>;
    }
    if (response is Map && response['content'] is List) {
      return response['content'] as List<dynamic>;
    }
    return [];
  }
}

/// A cached non-default pumping-status result with its fetch timestamp,
/// used to enforce [HomeRepositoryImpl._pumpingStatusCacheTtl].
class _CachedPumpingStatus {
  _CachedPumpingStatus(this.data) : fetchedAt = DateTime.now();

  final List<PumpingStatusEntity> data;
  final DateTime fetchedAt;
}

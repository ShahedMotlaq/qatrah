// lib/features/home/domain/repositories/i_home_repository.dart

import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/utils/pagination.dart';
import 'package:qatrah/features/home/domain/entities/area_entity.dart';
import 'package:qatrah/features/home/domain/entities/pumping_status_entity.dart';
import 'package:qatrah/features/home/domain/entities/schedule_entity.dart';

abstract class IHomeRepository {
  /// Get user's watched areas
  Future<Either<Failure, List<AreaEntity>>> getWatchedAreas();

  Future<Either<Failure, List<AreaEntity>>> getAllAreas();

  /// Get all available areas (for selection)
  Future<Either<Failure, Pagination<AreaEntity>>> getAvailableAreas({
    int page = 0,
    int size = 20,
    String? search,
  });

  /// Toggle area watch status
  Future<Either<Failure, void>> toggleAreaWatch(int areaId, bool watch);

  /// Get current pumping status for a location.
  ///
  /// When [isDefault] is true the consolidated `/schedules/home-status`
  /// endpoint is used (scoped server-side to the authenticated user's own
  /// home). When false, the specific zone (or neighbourhood) is queried and
  /// the status is assembled client-side, with a short-TTL cache.
  Future<Either<Failure, List<PumpingStatusEntity>>> getPumpingStatus({
    int? regionId,
    int? neighborhoodId,
    int? zoneId,
    bool isDefault = true,
  });

  /// Clears the cached non-default pumping-status entries (5-minute TTL).
  /// Call on explicit refresh or when a push notification signals a change.
  void clearPumpingStatusCache();

  /// Get upcoming schedules for watched areas
  Future<Either<Failure, Pagination<ScheduleEntity>>> getUpcomingSchedules({
    int page = 0,
    int size = 10,
    int? regionId,
    int? neighborhoodId,
    int? zoneId,
    List<int>? unitIds,
  });

  /// Get active schedule for feedback
  Future<Either<Failure, PumpingStatusEntity?>> getActiveScheduleForFeedback();

  /// Submit water feedback
  Future<Either<Failure, void>> submitWaterFeedback({
    required int scheduleId,
    required String feedbackType,
  });
}

import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

abstract class IDashboardRepository {
  Future<Either<Failure, List<ScheduleEntity>>> getSchedules({
    int? zoneId,
    String? status,
    String? sort,
    int? size,
    int? page,
  });
  Future<Either<Failure, List<LocationLookupEntity>>> getActiveRegions();
  Future<Either<Failure, void>> createSchedule({
    required int regionId,
    required DateTime start,
    required DateTime end,
    int? unitId,
    int? neighborhoodId,
    int? zoneId,
    String? notes,
  });

  Future<Either<Failure, void>> updateSchedule({
    required int scheduleId,
    required int regionId,
    required DateTime start,
    required DateTime end,
    int? unitId,
    int? neighborhoodId,
    int? zoneId,
    String? notes,
  });

  Future<Either<Failure, void>> startSchedule(int id);
  Future<Either<Failure, void>> endSchedule(int id);
  Future<Either<Failure, void>> pauseSchedule(int id, {String? pauseReason});
  Future<Either<Failure, void>> resumeSchedule(int id);
  Future<Either<Failure, void>> cancelSchedule(
    int id, {
    String? cancellationReason,
  });

  /// Delay the entire schedule by [hours] hours. The backend shifts both the
  /// start and end times against the same persistent schedule id.
  Future<Either<Failure, void>> shiftSchedule(int id, {required int hours});
}

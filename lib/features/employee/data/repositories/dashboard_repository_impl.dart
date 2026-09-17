import 'dart:developer' as dev;

import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/utils/input_sanitizer.dart';
import 'package:qatrah/core/utils/pagination.dart';
import 'package:qatrah/core/utils/user_helper.dart';
import 'package:qatrah/features/employee/data/models/schedule_model.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/employee/domain/repositories/i_employee_repository.dart';
import 'package:qatrah/features/profile/data/models/location_lookup_model.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

class DashboardRepositoryImpl implements IDashboardRepository {
  DashboardRepositoryImpl(this._apiService);
  final ApiService _apiService;

  @override
  Future<Either<Failure, List<ScheduleEntity>>> getSchedules({
    int? zoneId,
    String? status,
    String? sort,
    int? size,
    int? page,
  }) async {
    try {
      // One route for both roles: the server scopes an operator to their
      // assigned units and gives the admin everything. `zoneId` is a query
      // filter, not a separate path.
      final response = await _apiService.get(
        endPoint: ApiEndpoints.staffPumpingRuns,
        queryParameters: <String, dynamic>{
          if (zoneId != null) 'zoneId': zoneId,
          if (status != null && status.isNotEmpty) 'status': status,
          ...pageQuery(
            page: page,
            size: size,
            sort: sort == null || sort.isEmpty ? null : [sort],
          ),
        },
      );

      // Spring returns a Page: the rows live under `content`.
      final runs = Pagination.fromJson(response, ScheduleModelMapper.fromJson);

      return Right(runs.content);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorFetchingDashboardTables'));
    }
  }

  @override
  Future<Either<Failure, List<LocationLookupEntity>>> getActiveRegions() async {
    try {
      final response = await _apiService.get(
        endPoint: ApiEndpoints.activeRegions,
      );

      // Fix dynamic handling here as well using the same approach
      final data = (response['data'] as List<dynamic>?) ?? [];

      final regions = data
          .map(
            (e) =>
                LocationLookupModelMapper.fromJson(e as Map<String, dynamic>),
          )
          .toList();

      return Right(regions);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorFetchingRegions'));
    }
  }

  @override
  Future<Either<Failure, void>> createSchedule({
    required int regionId,
    required DateTime start,
    required DateTime end,
    int? unitId,
    int? neighborhoodId,
    int? zoneId,
    String? notes,
  }) async {
    try {
      final isOperator = await UserHelper.isOperator();
      final isAdmin = await UserHelper.isAdmin();

      if (isOperator && !isAdmin) {
        final assignedUnitIds = await UserHelper.getAssignedUnitIds();
        if (assignedUnitIds.isEmpty) {
          return Left(ServerFailure('noAssignedUnitsCannotAddSchedule'));
        }
        if (unitId == null || !assignedUnitIds.contains(unitId)) {
          return Left(ServerFailure('forbidden'));
        }
      }

      await _apiService.post(
        endPoint: ApiEndpoints.schedules,
        data: {
          'regionId': regionId,
          'unitId': ?unitId,
          'neighborhoodId': ?neighborhoodId,
          'zoneId': ?zoneId,
          'startTime': start.toIso8601String(),
          'endTime': end.toIso8601String(),
          if (notes != null && notes.isNotEmpty)
            'notes': InputSanitizer.sanitizeInput(notes),
          'status': 'SCHEDULED',
        },
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorCreatingSchedule'));
    }
  }

  @override
  Future<Either<Failure, void>> updateSchedule({
    required int scheduleId,
    required int regionId,
    required DateTime start,
    required DateTime end,
    int? unitId,
    int? neighborhoodId,
    int? zoneId,
    String? notes,
  }) async {
    try {
      await _apiService.put(
        endPoint: ApiEndpoints.updateSchedule(scheduleId),
        data: {
          'regionId': regionId,
          'unitId': ?unitId,
          'neighborhoodId': ?neighborhoodId,
          'zoneId': ?zoneId,
          'startTime': start.toIso8601String(),
          'endTime': end.toIso8601String(),
          if (notes != null && notes.isNotEmpty)
            'notes': InputSanitizer.sanitizeInput(notes),
        },
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorUpdatingSchedule'));
    }
  }

  @override
  Future<Either<Failure, void>> startSchedule(int id) async {
    try {
      // Defensive guard: verify operator has access to any unit
      // (We don't have unitId in schedule, so we check if operator has any assigned units)
      final assignedUnitIds = await UserHelper.getAssignedUnitIds();
      final isOperator = await UserHelper.isOperator();
      final isAdmin = await UserHelper.isAdmin();

      if (isOperator && !isAdmin && assignedUnitIds.isEmpty) {
        dev.log(
          '🚫 [Defensive Guard] Operator has no assigned units - blocking schedule start',
          name: 'Dashboard',
        );
        return Left(ServerFailure('noAssignedUnitsCannotAddSchedule'));
      }

      await _apiService.post(endPoint: ApiEndpoints.startSchedule(id));
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorStartingPumping'));
    }
  }

  @override
  Future<Either<Failure, void>> endSchedule(int id) async {
    try {
      // Defensive guard: verify operator has access to any unit
      final assignedUnitIds = await UserHelper.getAssignedUnitIds();
      final isOperator = await UserHelper.isOperator();
      final isAdmin = await UserHelper.isAdmin();

      if (isOperator && !isAdmin && assignedUnitIds.isEmpty) {
        dev.log(
          '🚫 [Defensive Guard] Operator has no assigned units - blocking schedule end',
          name: 'Dashboard',
        );
        return Left(ServerFailure('noAssignedUnitsCannotAddSchedule'));
      }

      await _apiService.post(endPoint: ApiEndpoints.endSchedule(id));
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorEndingPumping'));
    }
  }

  @override
  Future<Either<Failure, void>> pauseSchedule(
    int id, {
    String? pauseReason,
  }) async {
    try {
      final isOperator = await UserHelper.isOperator();
      final isAdmin = await UserHelper.isAdmin();

      if (!isAdmin && !isOperator) {
        dev.log(
          '🚫 [Defensive Guard] Non-operator/admin cannot pause schedule',
          name: 'Dashboard',
        );
        return Left(ServerFailure('forbidden'));
      }

      final sanitizedReason = pauseReason != null
          ? InputSanitizer.sanitizeInput(pauseReason)
          : null;
      final hasReason = sanitizedReason != null && sanitizedReason.isNotEmpty;
      await _apiService.post(
        endPoint: ApiEndpoints.pauseSchedule(id),
        data: hasReason ? {'pauseReason': sanitizedReason} : null,
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorPausingSchedule'));
    }
  }

  @override
  Future<Either<Failure, void>> resumeSchedule(int id) async {
    try {
      final isOperator = await UserHelper.isOperator();
      final isAdmin = await UserHelper.isAdmin();

      if (!isAdmin && !isOperator) {
        dev.log(
          '🚫 [Defensive Guard] Non-operator/admin cannot resume schedule',
          name: 'Dashboard',
        );
        return Left(ServerFailure('forbidden'));
      }

      await _apiService.post(endPoint: ApiEndpoints.resumeSchedule(id));
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorResumingSchedule'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelSchedule(
    int id, {
    String? cancellationReason,
  }) async {
    try {
      final sanitizedReason = cancellationReason != null
          ? InputSanitizer.sanitizeInput(cancellationReason)
          : null;
      final hasReason = sanitizedReason != null && sanitizedReason.isNotEmpty;
      await _apiService.post(
        endPoint: ApiEndpoints.cancelSchedule(id),
        data: hasReason ? {'cancellationReason': sanitizedReason} : null,
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorCancellingSchedule'));
    }
  }

  @override
  Future<Either<Failure, void>> shiftSchedule(
    int id, {
    required int hours,
    String? postponeReason,
  }) async {
    try {
      final isOperator = await UserHelper.isOperator();
      final isAdmin = await UserHelper.isAdmin();

      if (!isAdmin && !isOperator) {
        dev.log(
          '🚫 [Defensive Guard] Non-operator/admin cannot shift schedule',
          name: 'Dashboard',
        );
        return Left(ServerFailure('forbidden'));
      }

      if (hours <= 0) {
        return Left(ServerFailure('errorShiftingSchedule'));
      }

      final sanitizedReason = postponeReason != null
          ? InputSanitizer.sanitizeInput(postponeReason)
          : null;
      await _apiService.post(
        endPoint: ApiEndpoints.shiftSchedule(id),
        data: {
          'hours': hours,
          if (sanitizedReason != null && sanitizedReason.isNotEmpty)
            'reason': sanitizedReason,
        },
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorShiftingSchedule'));
    }
  }
}

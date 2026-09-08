// lib/features/home/domain/usecases/get_upcoming_schedules_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/utils/pagination.dart';
import 'package:qatrah/features/home/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/home/domain/repositories/i_home_repository.dart';

class GetUpcomingSchedulesUseCase {
  GetUpcomingSchedulesUseCase(this._repository);
  final IHomeRepository _repository;

  Future<Either<Failure, Pagination<ScheduleEntity>>> call({
    int page = 0,
    int size = 10,
    int? regionId,
    int? neighborhoodId,
    int? zoneId,
    List<int>? unitIds,
  }) async {
    return _repository.getUpcomingSchedules(
      page: page,
      size: size,
      regionId: regionId,
      neighborhoodId: neighborhoodId,
      zoneId: zoneId,
      unitIds: unitIds,
    );
  }
}

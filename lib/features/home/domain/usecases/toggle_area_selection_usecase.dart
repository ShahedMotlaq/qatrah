// lib/features/home/domain/usecases/toggle_area_watch_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/features/home/domain/repositories/i_home_repository.dart';

class ToggleAreaWatchUseCase {
  ToggleAreaWatchUseCase(this._repository);
  final IHomeRepository _repository;

  Future<Either<Failure, void>> call({
    required int areaId,
    required bool watch,
  }) async {
    return _repository.toggleAreaWatch(areaId, watch);
  }
}

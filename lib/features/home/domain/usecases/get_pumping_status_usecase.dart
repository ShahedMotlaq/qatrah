// lib/features/home/domain/usecases/get_pumping_status_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/features/home/domain/entities/pumping_status_entity.dart';
import 'package:qatrah/features/home/domain/repositories/i_home_repository.dart';

class GetPumpingStatusUseCase {
  GetPumpingStatusUseCase(this._repository);
  final IHomeRepository _repository;

  Future<Either<Failure, List<PumpingStatusEntity>>> call({
    int? regionId,
    int? neighborhoodId,
    int? zoneId,
    bool isDefault = true,
  }) async {
    return _repository.getPumpingStatus(
      regionId: regionId,
      neighborhoodId: neighborhoodId,
      zoneId: zoneId,
      isDefault: isDefault,
    );
  }

  /// Invalidates the non-default pumping-status cache (5-minute TTL).
  void clearCache() => _repository.clearPumpingStatusCache();
}

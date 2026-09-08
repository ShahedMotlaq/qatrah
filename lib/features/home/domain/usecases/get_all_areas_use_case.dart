// lib/features/home/domain/usecases/get_all_areas_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/features/home/domain/entities/area_entity.dart';
import 'package:qatrah/features/home/domain/repositories/i_home_repository.dart';

class GetAllAreasUseCase {
  GetAllAreasUseCase(this._repository);
  final IHomeRepository _repository;

  Future<Either<Failure, List<AreaEntity>>> call() async {
    return _repository.getAllAreas();
  }
}

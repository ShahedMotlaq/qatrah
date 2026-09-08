import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';
import 'package:qatrah/features/profile/domain/repositories/i_hierarchy_repository.dart';

class GetRegionsUseCase {
  GetRegionsUseCase(this._repository);
  final IHierarchyRepository _repository;
  Future<Either<Failure, List<LocationLookupEntity>>> call() async =>
      _repository.getRegions();
}

class GetUnitsUseCase {
  GetUnitsUseCase(this._repository);
  final IHierarchyRepository _repository;
  Future<Either<Failure, List<LocationLookupEntity>>> call(int id) async =>
      _repository.getUnits(id);
}

class GetNeighborhoodsUseCase {
  GetNeighborhoodsUseCase(this._repository);
  final IHierarchyRepository _repository;
  Future<Either<Failure, List<LocationLookupEntity>>> call(int id) async =>
      _repository.getNeighborhoods(id);
}

class GetZonesUseCase {
  GetZonesUseCase(this._repository);
  final IHierarchyRepository _repository;
  Future<Either<Failure, List<LocationLookupEntity>>> call(int id) async =>
      _repository.getZones(id);
}

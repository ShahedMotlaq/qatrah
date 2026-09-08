import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

abstract class IHierarchyRepository {
  Future<Either<Failure, List<LocationLookupEntity>>> getRegions();
  Future<Either<Failure, List<LocationLookupEntity>>> getUnits(int regionId);
  Future<Either<Failure, List<LocationLookupEntity>>> getNeighborhoods(
    int unitId,
  );
  Future<Either<Failure, List<LocationLookupEntity>>> getZones(
    int neighborhoodId,
  );
}

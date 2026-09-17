import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/features/profile/domain/entities/hierarchy_node_entity.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

abstract class IHierarchyRepository {
  /// The whole location tree — `GET /hierarchy/tree`, one request for all four
  /// levels. Cached for the session; pass [forceRefresh] to refetch.
  ///
  /// Returns the regions; each node holds its children.
  Future<Either<Failure, List<HierarchyNodeEntity>>> getTree({
    bool forceRefresh,
  });

  /// The four level readers below all slice the cached tree, so a cascading
  /// picker costs one request in total rather than one per level.
  Future<Either<Failure, List<LocationLookupEntity>>> getRegions();

  Future<Either<Failure, List<LocationLookupEntity>>> getUnits(int regionId);

  Future<Either<Failure, List<LocationLookupEntity>>> getNeighborhoods(
    int unitId,
  );

  Future<Either<Failure, List<LocationLookupEntity>>> getZones(
    int neighborhoodId,
  );
}

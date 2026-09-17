// lib/features/profile/data/repositories/hierarchy_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/features/profile/data/models/hierarchy_node_model.dart';
import 'package:qatrah/features/profile/domain/entities/hierarchy_node_entity.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';
import 'package:qatrah/features/profile/domain/repositories/i_hierarchy_repository.dart';

/// Backed by a single `GET /hierarchy/tree`, cached for the session.
///
/// The tree only changes when an admin edits the location master data, so
/// refetching it per level — or per picker — is wasted work. The four level
/// readers slice the cache instead, which also scopes each level to the parent
/// the user actually picked.
class HierarchyRepositoryImpl implements IHierarchyRepository {
  HierarchyRepositoryImpl(this._apiService);

  final ApiService _apiService;

  List<HierarchyNodeEntity>? _cache;

  /// Concurrent callers (four pickers building at once) await the same
  /// request rather than firing four.
  Future<List<HierarchyNodeEntity>>? _inFlight;

  @override
  Future<Either<Failure, List<HierarchyNodeEntity>>> getTree({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      _cache = null;
      _inFlight = null;
    }
    try {
      return Right(await _load());
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('Error fetching locations'));
    }
  }

  @override
  Future<Either<Failure, List<LocationLookupEntity>>> getRegions() =>
      _level(HierarchyLevel.region, null, 'Error fetching regions');

  @override
  Future<Either<Failure, List<LocationLookupEntity>>> getUnits(int regionId) =>
      _level(HierarchyLevel.unit, regionId, 'Error fetching units');

  @override
  Future<Either<Failure, List<LocationLookupEntity>>> getNeighborhoods(
    int unitId,
  ) => _level(HierarchyLevel.neighborhood, unitId, 'Error fetching neighborhoods');

  @override
  Future<Either<Failure, List<LocationLookupEntity>>> getZones(
    int neighborhoodId,
  ) => _level(HierarchyLevel.zone, neighborhoodId, 'Error fetching zones');

  /// Every node at [level] whose parent is [parentId] (all of them when
  /// [parentId] is null, which is only the case for regions).
  Future<Either<Failure, List<LocationLookupEntity>>> _level(
    HierarchyLevel level,
    int? parentId,
    String errorMessage,
  ) async {
    try {
      final tree = await _load();
      final out = <LocationLookupEntity>[];
      void visit(List<HierarchyNodeEntity> nodes) {
        for (final node in nodes) {
          if (node.level == level &&
              (parentId == null || node.parentId == parentId)) {
            out.add(node.asLookup);
          }
          // Levels are strictly ordered, so there is nothing to find below a
          // node that is already past the one we want.
          if (node.level.index < level.index) visit(node.children);
        }
      }

      visit(tree);
      return Right(out);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure(errorMessage));
    }
  }

  Future<List<HierarchyNodeEntity>> _load() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);

    final existing = _inFlight;
    if (existing != null) return existing;

    final future = _fetch();
    _inFlight = future;
    future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    return future;
  }

  Future<List<HierarchyNodeEntity>> _fetch() async {
    final response = await _apiService.get(
      endPoint: ApiEndpoints.hierarchyTree,
    );
    final tree = HierarchyNodeModelMapper.fromJsonList(_extractList(response));
    _cache = tree;
    return tree;
  }

  /// `/hierarchy/tree` answers with a bare JSON array, which ApiService wraps
  /// as `{'data': [...]}`.
  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      for (final key in const ['data', 'content']) {
        if (response[key] is List) return response[key] as List<dynamic>;
      }
    }
    return const [];
  }
}

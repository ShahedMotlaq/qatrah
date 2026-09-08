// lib/features/profile/data/repositories/hierarchy_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/features/profile/data/models/location_lookup_model.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';
import 'package:qatrah/features/profile/domain/repositories/i_hierarchy_repository.dart';

class HierarchyRepositoryImpl implements IHierarchyRepository {
  HierarchyRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<Either<Failure, List<LocationLookupEntity>>> getRegions() async {
    try {
      final response = await _apiService.get(
        endPoint: ApiEndpoints.activeRegions,
      );
      final list = _extractList(response)
          .map(
            (e) =>
                LocationLookupModelMapper.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      return Right(list);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure('Error fetching regions'));
    }
  }

  @override
  Future<Either<Failure, List<LocationLookupEntity>>> getUnits(
    int regionId,
  ) async {
    try {
      final response = await _apiService.get(
        endPoint: ApiEndpoints.activeUnitsByRegion(regionId),
      );
      final list = _extractList(response)
          .map(
            (e) =>
                LocationLookupModelMapper.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      return Right(list);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure('Error fetching units'));
    }
  }

  @override
  Future<Either<Failure, List<LocationLookupEntity>>> getNeighborhoods(
    int id,
  ) async {
    try {
      // User requested modification: use region/{id} path for neighborhoods
      final response = await _apiService.get(
        endPoint: ApiEndpoints.neighborhoodsByRegion(id),
      );
      final list = _extractList(response)
          .map(
            (e) =>
                LocationLookupModelMapper.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      return Right(list);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure('Error fetching neighborhoods'));
    }
  }

  @override
  Future<Either<Failure, List<LocationLookupEntity>>> getZones(
    int id,
  ) async {
    try {
      // User requested modification: use region/{id} path for zones
      final response = await _apiService.get(
        endPoint: ApiEndpoints.zonesByRegion(id),
      );
      final list = _extractList(response)
          .map(
            (e) =>
                LocationLookupModelMapper.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      return Right(list);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure('Error fetching zones'));
    }
  }

  /// Helper method to process data lists and prevent casting errors
  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      if (response.containsKey('data') && response['data'] is List) {
        return response['data'] as List<dynamic>;
      }
      if (response.containsKey('content') && response['content'] is List) {
        return response['content'] as List<dynamic>;
      }
    }
    return [];
  }
}

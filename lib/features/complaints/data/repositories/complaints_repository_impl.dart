import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/utils/input_sanitizer.dart';
import 'package:qatrah/core/utils/paginated_result.dart';
import 'package:qatrah/features/complaints/domain/entities/complaints_entity.dart';
import 'package:qatrah/features/complaints/domain/repositories/i_complaints_repository.dart';

class ComplaintsRepositoryImpl implements IComplaintsRepository {
  ComplaintsRepositoryImpl(this._apiService, this._secureStorage);

  final ApiService _apiService;
  final SecureStorage _secureStorage;

  @override
  Future<Either<Failure, PaginatedResult<ComplaintEntity>>> getMyComplaints({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiService.get(
        endPoint: ApiEndpoints.complaintsMy,
        queryParameters: {'page': page, 'size': size},
      );
      final result = _extractPaginated(response);
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorFetchingData'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<ComplaintEntity>>>
  getScopedComplaintsForEmployee({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final role = await _secureStorage.getRole();
      if (role == 'ADMIN') {
        final response = await _apiService.get(
          endPoint: ApiEndpoints.complaintsAll,
          queryParameters: {'page': page, 'size': size},
        );
        final result = _extractPaginated(response);
        final sorted = result.items
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Right(
          PaginatedResult(
            items: sorted,
            currentPage: result.currentPage,
            totalPages: result.totalPages,
            totalElements: result.totalElements,
            isLast: result.isLast,
          ),
        );
      }

      final profile = await _apiService.get(
        endPoint: ApiEndpoints.keycloakCurrentUser,
      );

      final complaintsMap = <int, ComplaintEntity>{};
      // ponytail: client-side merge of N region queries on one cursor. We page
      // every region in lockstep and report "more" if ANY region still has more.
      var anyHasMore = false;

      Future<void> loadByQuery(Map<String, dynamic> query) async {
        final response = await _apiService.get(
          endPoint: ApiEndpoints.complaintsSearch,
          queryParameters: {
            ...query,
            'page': page,
            'size': size,
          },
        );
        final result = _extractPaginated(response);
        for (final complaint in result.items) {
          complaintsMap[complaint.id] = complaint;
        }
        if (result.hasMore) anyHasMore = true;
      }

      final neighborhoodId = (profile['watchedNeighborhoodId'] as num?)
          ?.toInt();
      final regionId = (profile['watchedRegionId'] as num?)?.toInt();
      final assignedRegionIds = _extractIds(profile['assignedRegionIds']);
      if (assignedRegionIds.isEmpty) {
        assignedRegionIds.addAll(await _secureStorage.getAssignedRegionIds());
      }

      if (neighborhoodId != null && neighborhoodId > 0) {
        await loadByQuery({'neighborhoodId': neighborhoodId});
      } else if (regionId != null && regionId > 0) {
        await loadByQuery({'regionId': regionId});
      } else if (assignedRegionIds.isNotEmpty) {
        for (final assignedRegionId in assignedRegionIds) {
          await loadByQuery({'regionId': assignedRegionId});
        }
      } else {
        return const Right(
          PaginatedResult(
            items: [],
            currentPage: 0,
            totalPages: 0,
            totalElements: 0,
            isLast: true,
          ),
        );
      }

      final complaints = complaintsMap.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Right(
        PaginatedResult(
          items: complaints,
          currentPage: page,
          totalPages: anyHasMore ? page + 2 : page + 1,
          totalElements: complaints.length,
          isLast: !anyHasMore,
        ),
      );
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorFetchingData'));
    }
  }

  @override
  Future<Either<Failure, ComplaintEntity>> createComplaint({
    required String title,
    required String description,
    required String category,
  }) async {
    try {
      final regionId = await _secureStorage.getValue(DbKeys.regionId);
      final unitId = await _secureStorage.getValue(DbKeys.unitId);
      final neighborhoodId = await _secureStorage.getValue(
        DbKeys.neighborhoodId,
      );
      final zoneId = await _secureStorage.getValue(DbKeys.zoneId);

      final response = await _apiService.post(
        endPoint: ApiEndpoints.complaints,
        data: {
          'title': InputSanitizer.sanitizeInput(title),
          'description': InputSanitizer.sanitizeInput(description),
          'category': category,
          'regionId': int.tryParse(regionId ?? '0') ?? 0,
          'unitId': int.tryParse(unitId ?? '0') ?? 0,
          'neighborhoodId': int.tryParse(neighborhoodId ?? '0') ?? 0,
          'zoneId': int.tryParse(zoneId ?? '0') ?? 0,
        },
      );

      return Right(ComplaintEntity.fromJson(_extractComplaintObject(response)));
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorUpdatingData'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<ComplaintEntity>>>
  getComplaintsByNeighborhood(
    int neighborhoodId, {
    String? status,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'neighborhoodId': neighborhoodId,
        'page': page,
        'size': size,
      };

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      final response = await _apiService.get(
        endPoint: ApiEndpoints.complaintsSearch,
        queryParameters: queryParameters,
      );

      final result = _extractPaginated(response);
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorFetchingData'));
    }
  }

  @override
  Future<Either<Failure, void>> respondToComplaint({
    required int id,
    required String response,
    required String status,
  }) async {
    try {
      await _apiService.put(
        endPoint: ApiEndpoints.complaintById(id),
        data: {
          'status': status,
          'adminResponse': InputSanitizer.sanitizeInput(response),
        },
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorUpdatingData'));
    }
  }

  PaginatedResult<ComplaintEntity> _extractPaginated(
    Map<String, dynamic> response,
  ) {
    if (response.containsKey('totalPages') || response.containsKey('last')) {
      return PaginatedResult.fromJson(
        response,
        ComplaintEntity.fromJson,
      );
    }
    final data = response['data'];
    if (data is Map &&
        (data.containsKey('totalPages') || data.containsKey('last'))) {
      return PaginatedResult.fromJson(
        Map<String, dynamic>.from(data),
        ComplaintEntity.fromJson,
      );
    }
    final items = _extractList(response).map(ComplaintEntity.fromJson).toList();
    return PaginatedResult(
      items: items,
      currentPage: 0,
      totalPages: 1,
      totalElements: items.length,
      isLast: true,
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic response) {
    final dataNode =
        response is Map<String, dynamic> && response['data'] != null
        ? response['data']
        : response;

    List<dynamic> data;
    if (dataNode is Map && dataNode.containsKey('content')) {
      data = dataNode['content'] as List<dynamic>? ?? [];
    } else if (dataNode is Map && dataNode['items'] is List) {
      data = dataNode['items'] as List<dynamic>;
    } else if (dataNode is List) {
      data = dataNode;
    } else {
      data = [];
    }

    return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Map<String, dynamic> _extractComplaintObject(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return response;
  }

  Set<int> _extractIds(dynamic value) {
    if (value is! List) return <int>{};
    return value
        .map((e) {
          if (e is num) return e.toInt();
          if (e is Map) return (e['id'] as num?)?.toInt();
          return int.tryParse(e.toString());
        })
        .whereType<int>()
        .toSet();
  }
}

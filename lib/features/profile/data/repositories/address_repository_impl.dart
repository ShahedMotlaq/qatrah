import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/utils/app_logger.dart';
import 'package:qatrah/core/utils/input_sanitizer.dart';
import 'package:qatrah/features/profile/data/models/address_model.dart';
import 'package:qatrah/features/profile/domain/entities/address_entity.dart';
import 'package:qatrah/features/profile/domain/repositories/i_address_repository.dart';

class AddressRepositoryImpl implements IAddressRepository {
  AddressRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<Either<Failure, List<AddressEntity>>> getAddresses() async {
    try {
      final response = await _apiService.get(endPoint: ApiEndpoints.addresses);
      AppLogger.debug(
        '[ADDRESSES] raw response keys: ${response.keys.toList()}',
      );
      AppLogger.debug('[ADDRESSES] raw response: $response');
      final list = _extractAddressList(response);
      AppLogger.debug('[ADDRESSES] extracted ${list.length} items');
      final addresses = list.map(AddressModelMapper.fromJson).toList();
      return Right(addresses);
    } on Failure catch (f) {
      AppLogger.error('[ADDRESSES] Failure: ${f.errMessage}');
      return Left(f);
    } catch (e) {
      AppLogger.error('[ADDRESSES] Exception: $e');
      return Left(ServerFailure('Error fetching addresses'));
    }
  }

  @override
  Future<Either<Failure, AddressEntity>> createAddress({
    required String title,
    required int regionId,
    required int unitId,
    required int neighborhoodId,
    required int zoneId,
  }) async {
    try {
      final response = await _apiService.post(
        endPoint: ApiEndpoints.addresses,
        data: {
          'title': InputSanitizer.sanitizeInput(title),
          'regionId': regionId,
          'unitId': unitId,
          'neighborhoodId': neighborhoodId,
          'zoneId': zoneId,
        },
      );
      return Right(AddressModelMapper.fromJson(_unwrapAddress(response)));
    } on Failure catch (f) {
      return Left(_mapConflictFailure(f));
    } catch (e) {
      return Left(ServerFailure('Error creating address'));
    }
  }

  @override
  Future<Either<Failure, AddressEntity>> updateAddress({
    required int id,
    required String title,
    required int regionId,
    required int unitId,
    required int neighborhoodId,
    required int zoneId,
  }) async {
    try {
      final response = await _apiService.put(
        endPoint: '${ApiEndpoints.addresses}/$id',
        data: {
          'title': InputSanitizer.sanitizeInput(title),
          'regionId': regionId,
          'unitId': unitId,
          'neighborhoodId': neighborhoodId,
          'zoneId': zoneId,
        },
      );
      return Right(AddressModelMapper.fromJson(_unwrapAddress(response)));
    } on Failure catch (f) {
      return Left(_mapConflictFailure(f));
    } catch (e) {
      return Left(ServerFailure('Error updating address'));
    }
  }

  /// Maps a 409 Conflict response (encoded as S8) to a friendly duplicate key.
  Failure _mapConflictFailure(Failure f) {
    if (f.errMessage.endsWith('|S8')) {
      return ServerFailure('duplicate_address_found');
    }
    return f;
  }

  @override
  Future<Either<Failure, void>> deleteAddress(int id) async {
    try {
      await _apiService.delete(
        endPoint: ApiEndpoints.addresses,
        id: id.toString(),
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure('Error deleting address'));
    }
  }

  @override
  Future<Either<Failure, AddressEntity>> setDefaultAddress(int id) async {
    try {
      final response = await _apiService.patch(
        endPoint: '${ApiEndpoints.addresses}/$id/set-default',
      );
      return Right(AddressModelMapper.fromJson(_unwrapAddress(response)));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure('Error setting default address'));
    }
  }

  List<Map<String, dynamic>> _extractAddressList(dynamic response) {
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      final content = response['content'];
      if (content is List) {
        return content.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _unwrapAddress(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return response;
    }
    return const <String, dynamic>{};
  }
}

import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/features/profile/domain/entities/address_entity.dart';

abstract class IAddressRepository {
  Future<Either<Failure, List<AddressEntity>>> getAddresses();

  Future<Either<Failure, AddressEntity>> createAddress({
    required String title,
    required int regionId,
    required int unitId,
    required int neighborhoodId,
    required int zoneId,
  });

  Future<Either<Failure, AddressEntity>> updateAddress({
    required int id,
    required String title,
    required int regionId,
    required int unitId,
    required int neighborhoodId,
    required int zoneId,
  });

  Future<Either<Failure, void>> deleteAddress(int id);

  Future<Either<Failure, AddressEntity>> setDefaultAddress(int id);
}

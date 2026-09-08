import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/utils/input_sanitizer.dart';
import 'package:qatrah/features/auth/domain/entities/user_entity.dart';
import 'package:qatrah/features/profile/domain/repositories/i_profile_repository.dart';

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({
    required this.fullName,
    required this.regionId,
    required this.unitId,
    required this.neighborhoodId,
    required this.zoneId,
  });
  final String fullName;
  final int regionId;
  final int unitId;
  final int neighborhoodId;
  final int zoneId;

  Map<String, dynamic> toJson() => {
    'fullName': InputSanitizer.sanitizeInput(fullName),
    'regionId': regionId,
    'unitId': unitId,
    'neighborhoodId': neighborhoodId,
    'zoneId': zoneId,
  };

  @override
  List<Object?> get props => [
    fullName,
    regionId,
    unitId,
    neighborhoodId,
    zoneId,
  ];
}

class UpdateProfileUseCase {
  UpdateProfileUseCase(this._repository);
  final IProfileRepository _repository;

  Future<Either<Failure, UserEntity>> call(UpdateProfileParams params) async {
    return _repository.updateProfile(params);
  }
}

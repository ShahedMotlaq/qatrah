import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/utils/paginated_result.dart';
import 'package:qatrah/features/complaints/domain/entities/complaints_entity.dart';
import 'package:qatrah/features/complaints/domain/repositories/i_complaints_repository.dart';

class GetMyComplaintsUseCase {
  GetMyComplaintsUseCase(this._repository);
  final IComplaintsRepository _repository;

  Future<Either<Failure, PaginatedResult<ComplaintEntity>>> call({
    int page = 0,
    int size = 20,
  }) async {
    return _repository.getMyComplaints(page: page, size: size);
  }
}

class CreateComplaintUseCase {
  CreateComplaintUseCase(this._repository);
  final IComplaintsRepository _repository;

  Future<Either<Failure, ComplaintEntity>> call(
    String title,
    String desc,
    String category,
  ) async {
    return _repository.createComplaint(
      title: title,
      description: desc,
      category: category,
    );
  }
}

class GetScopedComplaintsForEmployeeUseCase {
  GetScopedComplaintsForEmployeeUseCase(this._repository);
  final IComplaintsRepository _repository;

  Future<Either<Failure, PaginatedResult<ComplaintEntity>>> call({
    int page = 0,
    int size = 20,
  }) async {
    return _repository.getScopedComplaintsForEmployee(
      page: page,
      size: size,
    );
  }
}

class RespondToComplaintUseCase {
  RespondToComplaintUseCase(this._repository);
  final IComplaintsRepository _repository;

  Future<Either<Failure, void>> call({
    required int id,
    required String response,
    required String status,
  }) async {
    return _repository.respondToComplaint(
      id: id,
      response: response,
      status: status,
    );
  }
}

class GetComplaintsByNeighborhoodUseCase {
  GetComplaintsByNeighborhoodUseCase(this._repository);
  final IComplaintsRepository _repository;

  Future<Either<Failure, PaginatedResult<ComplaintEntity>>> call({
    required int neighborhoodId,
    String? status,
    int page = 0,
    int size = 50,
  }) async {
    return _repository.getComplaintsByNeighborhood(
      neighborhoodId,
      status: status,
      page: page,
      size: size,
    );
  }
}

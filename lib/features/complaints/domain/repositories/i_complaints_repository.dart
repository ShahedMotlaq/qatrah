import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/utils/paginated_result.dart';
import 'package:qatrah/features/complaints/domain/entities/complaints_entity.dart';

abstract class IComplaintsRepository {
  Future<Either<Failure, PaginatedResult<ComplaintEntity>>> getMyComplaints({
    int page = 0,
    int size = 20,
  });

  Future<Either<Failure, PaginatedResult<ComplaintEntity>>>
  getScopedComplaintsForEmployee({
    int page = 0,
    int size = 20,
  });

  Future<Either<Failure, ComplaintEntity>> createComplaint({
    required String title,
    required String description,
    required String category,
  });

  Future<Either<Failure, PaginatedResult<ComplaintEntity>>>
  getComplaintsByNeighborhood(
    int neighborhoodId, {
    String? status,
    int page = 0,
    int size = 50,
  });

  Future<Either<Failure, void>> respondToComplaint({
    required int id,
    required String response,
    required String status,
  });
}

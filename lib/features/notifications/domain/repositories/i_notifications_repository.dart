import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/utils/paginated_result.dart';
import 'package:qatrah/features/notifications/domain/entities/notifications_entity.dart';

abstract class INotificationsRepository {
  Future<Either<Failure, PaginatedResult<NotificationEntity>>>
  getNotifications({
    int page = 0,
    int size = 20,
  });

  Future<Either<Failure, PaginatedResult<NotificationEntity>>>
  getPublicNotifications({
    int? regionId,
    int page = 0,
    int size = 20,
  });

  Future<Either<Failure, int>> getUnreadCount();

  Future<Either<Failure, void>> markAsRead(int id);

  Future<Either<Failure, void>> markAllAsRead();
}

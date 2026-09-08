import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/utils/paginated_result.dart';
import 'package:qatrah/features/notifications/domain/entities/notifications_entity.dart';
import 'package:qatrah/features/notifications/domain/repositories/i_notifications_repository.dart';

class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);
  final INotificationsRepository _repository;

  Future<Either<Failure, PaginatedResult<NotificationEntity>>> call({
    int page = 0,
    int size = 20,
  }) async => _repository.getNotifications(page: page, size: size);
}

class GetPublicNotificationsUseCase {
  GetPublicNotificationsUseCase(this._repository);
  final INotificationsRepository _repository;

  Future<Either<Failure, PaginatedResult<NotificationEntity>>> call({
    int? regionId,
    int page = 0,
    int size = 20,
  }) async => _repository.getPublicNotifications(
    regionId: regionId,
    page: page,
    size: size,
  );
}

class GetUnreadCountUseCase {
  GetUnreadCountUseCase(this._repository);
  final INotificationsRepository _repository;

  Future<Either<Failure, int>> call() async => _repository.getUnreadCount();
}

class MarkNotificationAsReadUseCase {
  MarkNotificationAsReadUseCase(this._repository);
  final INotificationsRepository _repository;

  Future<Either<Failure, void>> call(int id) async =>
      _repository.markAsRead(id);
}

import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/core/utils/paginated_result.dart';
import 'package:qatrah/features/notifications/data/models/notification_model.dart';
import 'package:qatrah/features/notifications/domain/entities/notifications_entity.dart';
import 'package:qatrah/features/notifications/domain/repositories/i_notifications_repository.dart';

class NotificationsRepositoryImpl implements INotificationsRepository {
  NotificationsRepositoryImpl(this._apiService);
  final ApiService _apiService;

  @override
  Future<Either<Failure, PaginatedResult<NotificationEntity>>>
  getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiService.get(
        endPoint: ApiEndpoints.notifications,
        queryParameters: {'page': page, 'size': size},
      );
      final result = _extractPaginated(response);
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorFetchingNotifications'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<NotificationEntity>>>
  getPublicNotifications({
    int? regionId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final endPoint = regionId != null
          ? ApiEndpoints.notificationsPublicByRegion(regionId)
          : ApiEndpoints.notificationsPublic;
      final response = await _apiService.get(
        endPoint: endPoint,
        queryParameters: {'page': page, 'size': size},
      );
      final result = _extractPaginated(response);
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorFetchingNotifications'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final response = await _apiService.get(
        endPoint: ApiEndpoints.notificationsUnreadCount,
      );
      final data = response['data'] ?? response;
      if (data is num) return Right(data.toInt());
      if (data is Map<String, dynamic>) {
        final count = data['count'] ?? data['unreadCount'];
        if (count is num) return Right(count.toInt());
        if (count is String) return Right(int.tryParse(count) ?? 0);
      }
      return const Right(0);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorFetchingNotifications'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(int id) async {
    try {
      await _apiService.put(
        endPoint: ApiEndpoints.notificationRead(id),
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorUpdatingNotificationStatus'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await _apiService.put(
        endPoint: ApiEndpoints.notificationsReadAll,
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('errorUpdatingAllNotifications'));
    }
  }

  PaginatedResult<NotificationEntity> _extractPaginated(
    Map<String, dynamic> response,
  ) {
    final raw = response;
    if (raw.containsKey('totalPages') || raw.containsKey('last')) {
      return PaginatedResult.fromJson(
        raw,
        NotificationModelMapper.fromJson,
      );
    }
    final data = raw['data'];
    if (data is Map &&
        (data.containsKey('totalPages') || data.containsKey('last'))) {
      return PaginatedResult.fromJson(
        Map<String, dynamic>.from(data),
        NotificationModelMapper.fromJson,
      );
    }
    final items = _extractList(raw);
    return PaginatedResult(
      items: items.map(NotificationModelMapper.fromJson).toList(),
      currentPage: 0,
      totalPages: 1,
      totalElements: items.length,
      isLast: true,
    );
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map) {
      final inner = data['content'] ?? data['data'] ?? data['notifications'];
      if (inner is List)
        return inner.whereType<Map<String, dynamic>>().toList();
    }
    final root =
        response['content'] ?? response['notifications'] ?? response['items'];
    if (root is List) return root.whereType<Map<String, dynamic>>().toList();
    return const [];
  }
}

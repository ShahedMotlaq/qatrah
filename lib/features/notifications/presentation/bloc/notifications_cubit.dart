import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/features/notifications/domain/entities/notifications_entity.dart';
import 'package:qatrah/features/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:qatrah/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:qatrah/features/notifications/presentation/bloc/notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(
    this._getNotifications,
    this._getPublicNotifications,
    this._repository,
    this._getUnreadCount,
  ) : super(NotificationsInitial());
  final GetNotificationsUseCase _getNotifications;
  final GetPublicNotificationsUseCase _getPublicNotifications;
  final GetUnreadCountUseCase _getUnreadCount;
  final INotificationsRepository _repository;
  final SecureStorage _storage = getIt<SecureStorage>();

  Timer? _autoRefreshTimer;
  bool _isEmployee = false;

  static const _readIdsKey = 'notifications_read_ids';
  static const _legacyUnreadIdsKey = 'notifications_unread_ids';
  static const int _pageSize = 20;
  static const int _autoRefreshIntervalSeconds = 30;

  Future<void> fetchNotifications({bool isEmployee = false}) async {
    _isEmployee = isEmployee;
    emit(NotificationsLoading());
    try {
      final result = isEmployee
          ? await _getPublicNotifications()
          : await _getNotifications();

      await result.fold(
        (f) async {
          if (!isClosed) emit(NotificationsError(f.errMessage));
        },
        (paginated) async {
          var filtered = _filterByAge(paginated.items);
          // Filter by selected area if a home address is set
          if (!isEmployee) {
            final selectedLocation = await _storage
                .getSelectedHomeLocationName();
            if (selectedLocation != null && selectedLocation.isNotEmpty) {
              filtered = filtered
                  .where(
                    (n) =>
                        (n.neighborhoodName != null &&
                            n.neighborhoodName!.contains(selectedLocation)) ||
                        (n.zoneName != null &&
                            n.zoneName!.contains(selectedLocation)) ||
                        n.neighborhoodName == null && n.zoneName == null,
                  )
                  .toList();
            }
          }
          final merged = await _applyLocalReadState(filtered).timeout(
            const Duration(seconds: 5),
            onTimeout: () => filtered,
          );
          if (!isClosed) {
            emit(
              NotificationsLoaded(
                merged,
                unreadCount: _unreadCount(merged),
                currentPage: paginated.currentPage,
                hasMore: paginated.hasMore,
              ),
            );
          }
          _startAutoRefresh();
        },
      );
    } catch (_) {
      if (!isClosed) {
        emit(const NotificationsError('errorFetchingNotifications'));
      }
    }
  }

  Future<void> fetchNextPage({bool isEmployee = false}) async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    if (current.fetchingNextPage || !current.hasMore) return;

    emit(current.copyWith(fetchingNextPage: true));
    final nextPage = current.currentPage + 1;

    try {
      final result = isEmployee
          ? await _getPublicNotifications(page: nextPage)
          : await _getNotifications(page: nextPage);

      await result.fold(
        (f) async {
          if (!isClosed) {
            emit(current.copyWith(fetchingNextPage: false));
          }
        },
        (paginated) async {
          var filteredNew = _filterByAge(paginated.items);
          if (!isEmployee) {
            final selectedLocation = await _storage
                .getSelectedHomeLocationName();
            if (selectedLocation != null && selectedLocation.isNotEmpty) {
              filteredNew = filteredNew
                  .where(
                    (n) =>
                        (n.neighborhoodName != null &&
                            n.neighborhoodName!.contains(selectedLocation)) ||
                        (n.zoneName != null &&
                            n.zoneName!.contains(selectedLocation)) ||
                        n.neighborhoodName == null && n.zoneName == null,
                  )
                  .toList();
            }
          }
          final mergedNew = await _applyLocalReadState(filteredNew).timeout(
            const Duration(seconds: 5),
            onTimeout: () => filteredNew,
          );
          final combined = [...current.notifications, ...mergedNew];
          final totalUnread = _unreadCount(combined);
          if (!isClosed) {
            emit(
              NotificationsLoaded(
                combined,
                unreadCount: totalUnread,
                currentPage: paginated.currentPage,
                hasMore: paginated.hasMore,
              ),
            );
          }
        },
      );
    } catch (_) {
      if (!isClosed && !isClosed) {
        emit(current.copyWith(fetchingNextPage: false));
      }
    }
  }

  Future<void> refresh({bool isEmployee = false}) async {
    final current = state;
    if (current is NotificationsLoaded) {
      await _silentFetchNotifications(isEmployee);
    } else {
      await fetchNotifications(isEmployee: isEmployee);
    }
  }

  Future<void> _silentFetchNotifications(bool isEmployee) async {
    try {
      final result = isEmployee
          ? await _getPublicNotifications()
          : await _getNotifications();

      await result.fold(
        (f) async {
          if (!isClosed) {
            final current = state;
            if (current is NotificationsLoaded) {
              emit(current.copyWith());
            }
          }
        },
        (paginated) async {
          var filtered = _filterByAge(paginated.items);
          if (!isEmployee) {
            final selectedLocation = await _storage
                .getSelectedHomeLocationName();
            if (selectedLocation != null && selectedLocation.isNotEmpty) {
              filtered = filtered
                  .where(
                    (n) =>
                        (n.neighborhoodName != null &&
                            n.neighborhoodName!.contains(selectedLocation)) ||
                        (n.zoneName != null &&
                            n.zoneName!.contains(selectedLocation)) ||
                        n.neighborhoodName == null && n.zoneName == null,
                  )
                  .toList();
            }
          }
          final merged = await _applyLocalReadState(filtered).timeout(
            const Duration(seconds: 5),
            onTimeout: () => filtered,
          );
          if (!isClosed) {
            emit(
              NotificationsLoaded(
                merged,
                unreadCount: _unreadCount(merged),
                currentPage: paginated.currentPage,
                hasMore: paginated.hasMore,
              ),
            );
          }
        },
      );
    } catch (_) {
      // Silently fail on auto-refresh
    }
  }

  Future<void> fetchUnreadCount() async {
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      emit(current.copyWith(unreadCount: _unreadCount(current.notifications)));
      return;
    }
    final result = await _getUnreadCount();
    result.fold((_) {}, (_) {});
  }

  Future<void> markAsRead(int id) async {
    final readIds = await _getLocalReadIds();
    readIds.add(id);
    await _saveLocalReadIds(readIds);
    await _removeLegacyUnreadId(id);

    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      final updated = current.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      emit(
        current.copyWith(
          notifications: updated,
          unreadCount: _unreadCount(updated),
        ),
      );
    }
  }

  Future<void> markAllRead() async {
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      final readIds = await _getLocalReadIds();
      readIds.addAll(current.notifications.map((n) => n.id));
      await _saveLocalReadIds(readIds);
      await _clearLegacyUnreadIds();

      final updated = current.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      emit(
        current.copyWith(
          notifications: updated,
          unreadCount: 0,
        ),
      );
    } else {
      await _clearLegacyUnreadIds();
    }

    _repository.markAllAsRead();
  }

  List<NotificationEntity> _filterByAge(
    List<NotificationEntity> notifications,
  ) {
    final now = DateTime.now();
    return notifications
        .where((n) => now.difference(n.createdAt).inDays < 90)
        .toList();
  }

  void _startAutoRefresh() {
    _stopAutoRefresh();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: _autoRefreshIntervalSeconds),
      (_) => refresh(isEmployee: _isEmployee),
    );
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  Future<void> close() {
    _stopAutoRefresh();
    return super.close();
  }

  Future<List<NotificationEntity>> _applyLocalReadState(
    List<NotificationEntity> notifications,
  ) async {
    final readIds = await _getLocalReadIds();
    final serverReadIds = notifications.where((n) => n.isRead).map((n) => n.id);
    readIds.addAll(serverReadIds);
    await _saveLocalReadIds(readIds);

    return notifications
        .map((n) => n.copyWith(isRead: readIds.contains(n.id)))
        .toList();
  }

  int _unreadCount(List<NotificationEntity> notifications) =>
      notifications.where((n) => !n.isRead).length;

  Future<Set<int>> _getLocalReadIds() => _getIds(_readIdsKey);

  Future<Set<int>> _getIds(String key) async {
    final raw = await _storage.getDynamicValue(key);
    if (raw == null || raw.trim().isEmpty) return <int>{};
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toSet();
  }

  Future<void> _saveLocalReadIds(Set<int> ids) async {
    await _storage.setDynamicValue(_readIdsKey, ids.join(','));
  }

  Future<void> _removeLegacyUnreadId(int id) async {
    final legacyUnreadIds = await _getIds(_legacyUnreadIdsKey);
    if (legacyUnreadIds.remove(id)) {
      await _storage.setDynamicValue(
        _legacyUnreadIdsKey,
        legacyUnreadIds.join(','),
      );
    }
  }

  Future<void> _clearLegacyUnreadIds() async {
    await _storage.deleteDynamicValue(_legacyUnreadIdsKey);
  }
}

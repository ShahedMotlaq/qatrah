import 'package:equatable/equatable.dart';
import 'package:qatrah/features/notifications/domain/entities/notifications_entity.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(
    this.notifications, {
    this.unreadCount = 0,
    this.currentPage = 0,
    this.hasMore = true,
    this.fetchingNextPage = false,
  });
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final int currentPage;
  final bool hasMore;
  final bool fetchingNextPage;

  bool get hasUnread => unreadCount > 0;

  @override
  List<Object?> get props => [
    notifications,
    unreadCount,
    currentPage,
    hasMore,
    fetchingNextPage,
  ];

  NotificationsLoaded copyWith({
    List<NotificationEntity>? notifications,
    int? unreadCount,
    int? currentPage,
    bool? hasMore,
    bool? fetchingNextPage,
  }) {
    return NotificationsLoaded(
      notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      fetchingNextPage: fetchingNextPage ?? this.fetchingNextPage,
    );
  }
}

class NotificationsError extends NotificationsState {
  const NotificationsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

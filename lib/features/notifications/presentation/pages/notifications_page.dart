import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/settings_storage_service.dart';
import 'package:qatrah/core/utils/app_date_formatter.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/app_empty_state_widget.dart';
import 'package:qatrah/core/widgets/app_failure_view.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_refresh_indicator.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/features/notifications/domain/entities/notification_type.dart';
import 'package:qatrah/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:qatrah/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:qatrah/features/notifications/presentation/widgets/notification_type.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _notificationPermissionDenied = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _determineAndFetch();
    });
  }

  Future<void> _determineAndFetch() async {
    final storage = SecureStorage();
    final role = await storage.getRole();
    final isEmployee =
        role == 'ADMIN' || role == 'OPERATOR' || role == 'EMPLOYEE';
    if (!mounted) return;
    context.read<NotificationsCubit>().fetchNotifications(
      isEmployee: isEmployee,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.7;

    if (currentScroll >= threshold) {
      final state = context.read<NotificationsCubit>().state;
      if (state is NotificationsLoaded &&
          state.hasMore &&
          !state.fetchingNextPage) {
        _determineAndFetchNextPage();
      }
    }
  }

  Future<void> _determineAndFetchNextPage() async {
    final storage = SecureStorage();
    final role = await storage.getRole();
    final isEmployee =
        role == 'ADMIN' || role == 'OPERATOR' || role == 'EMPLOYEE';
    if (!mounted) return;
    context.read<NotificationsCubit>().fetchNextPage(isEmployee: isEmployee);
  }

  Future<void> _checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      dev.log(
        '🔐 [NotificationsPage] permission status: $status',
        name: 'NOTIF',
      );
      if (!mounted) return;
      setState(() {
        _notificationPermissionDenied =
            status.isDenied || status.isPermanentlyDenied;
      });
    } catch (e) {
      dev.log(
        '❌ [NotificationsPage] Error checking permission: $e',
        name: 'NOTIF',
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      dev.log(
        '🔐 [NotificationsPage] permission request result: $status',
        name: 'NOTIF',
      );

      if (!mounted) return;

      if (status.isGranted) {
        setState(() {
          _notificationPermissionDenied = false;
        });
        final settingsStorage = getIt<SettingsStorageService>();
        await settingsStorage.setNotificationsEnabled(true);
        _determineAndFetch();
      } else if (status.isPermanentlyDenied) {
        dev.log(
          '⚠️ [NotificationsPage] Permission permanently denied',
          name: 'NOTIF',
        );
        if (!mounted) return;
        openAppSettings();
      }
    } catch (e) {
      dev.log(
        '❌ [NotificationsPage] Error requesting permission: $e',
        name: 'NOTIF',
      );
    }
  }

  Future<void> _determineAndRefresh() async {
    final storage = SecureStorage();
    final role = await storage.getRole();
    final isEmployee =
        role == 'ADMIN' || role == 'OPERATOR' || role == 'EMPLOYEE';
    if (!mounted) return;
    await context.read<NotificationsCubit>().refresh(isEmployee: isEmployee);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final banner = Container(
      width: double.infinity,
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.notificationPermissionSettingsRequired,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.onPrimary.withValues(
                alpha: 0.16,
              ),
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            onPressed: () async {
              final status = await Permission.notification.request();
              if (status.isPermanentlyDenied) {
                if (!mounted) return;
                await openAppSettings();
              } else if (status.isGranted) {
                if (!mounted) return;
                await _checkNotificationPermission();
              }
            },
            child: Text(l10n.enablePermission),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: QatrahAppBarWidget(
        title: Text(l10n.notificationsTab),
        actions: [
          Builder(
            builder: (ctx) => InkWell(
              borderRadius: BorderRadius.circular(100.r),
              onTap: () => ctx.read<NotificationsCubit>().markAllRead(),
              child: AppIconWidget(
                icon: HugeIcons.strokeRoundedCheckmarkBadge04,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_notificationPermissionDenied) banner,
          Expanded(
            child: AppBackground(
              child: AppRefreshIndicator(
                onRefresh: _determineAndRefresh,
                child: BlocBuilder<NotificationsCubit, NotificationsState>(
                  // Rebuild on state-type changes and list changes only; skip
                  // Loaded→Loaded transitions that just toggle pagination flags
                  // (fetchingNextPage/hasMore) — they don't affect this list.
                  buildWhen: (prev, curr) {
                    if (prev.runtimeType != curr.runtimeType) return true;
                    if (prev is NotificationsLoaded &&
                        curr is NotificationsLoaded) {
                      return prev.notifications != curr.notifications;
                    }
                    return true;
                  },
                  builder: (context, state) {
                    if (state is NotificationsInitial ||
                        state is NotificationsLoading) {
                      return Skeletonizer(
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          separatorBuilder: (_, _) => 12.verticalSpace,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 24,
                          ),
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return NotificationItemWidget(
                              type: NotificationType.start,
                              title: l10n.notificationsTab,
                              body: l10n.noNotificationsCurrently,
                              time: '',
                              isUnread: index % 2 == 0,
                            );
                          },
                        ),
                      );
                    } else if (state is NotificationsError) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: AppFailureView(
                              message: _mapNotificationError(state.message),
                              onRetry: _determineAndFetch,
                            ),
                          ),
                        ],
                      );
                    } else if (state is NotificationsLoaded) {
                      if (state.notifications.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: AppEmptyState(
                                message: l10n.noNotificationsCurrently,
                                icon: HugeIcons.strokeRoundedNotification01,
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        separatorBuilder: (_, _) => 12.verticalSpace,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 24,
                        ),
                        itemCount: state.notifications.length,
                        itemBuilder: (context, index) {
                          final item = state.notifications[index];

                          final locationDetails = item.formatLocationDetails();
                          final displayBody = locationDetails.isNotEmpty
                              ? locationDetails
                              : item.message;

                          return InkWell(
                            onTap: () {
                              if (!item.isRead) {
                                context.read<NotificationsCubit>().markAsRead(
                                  item.id,
                                );
                              }

                              if (item.pumpingScheduleId != null) {
                                context.goNamed(
                                  Routes.navbar,
                                  extra: <String, dynamic>{
                                    'fromNotification': true,
                                    'scheduleId': item.pumpingScheduleId,
                                    'regionName': item.regionName,
                                    'unitName': item.unitName,
                                    'neighborhoodName': item.neighborhoodName,
                                    'zoneName': item.zoneName,
                                  },
                                );
                              }
                            },
                            child: NotificationItemWidget(
                              type: item.type,
                              title: item.title,
                              body: displayBody,
                              time: AppDateFormatter.formatSmartDateTime(
                                item.createdAt,
                                context,
                              ),
                              isUnread: !item.isRead,
                            ),
                          );
                        },
                      );
                    }
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: AppEmptyState(
                            message: l10n.noNotificationsCurrently,
                            icon: HugeIcons.strokeRoundedNotification01,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mapNotificationError(String message) {
    final l10n = context.l10n;
    switch (message.trim()) {
      case 'errorFetchingNotifications':
        return l10n.errorFetchingNotifications;
      case 'errorUpdatingNotificationStatus':
        return l10n.errorUpdatingNotificationStatus;
      case 'errorUpdatingAllNotifications':
        return l10n.errorUpdatingAllNotifications;
      case 'forbidden':
        return l10n.forbidden;
      default:
        return l10n.errorOccurred;
    }
  }
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/notification/notification_service.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_stats.dart';
import 'package:qatrah/features/employee/domain/repositories/i_employee_repository.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';

class StatisticsState extends Equatable {
  const StatisticsState({
    this.stats,
    this.updatedAt,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Null until the first successful load; kept across failed refreshes so
  /// the screen never blanks out on a flaky network.
  final ScheduleStats? stats;
  final DateTime? updatedAt;
  final bool isLoading;
  final String? errorMessage;

  @override
  List<Object?> get props => [stats, updatedAt, isLoading, errorMessage];
}

/// Keeps [ScheduleStats] current while the Statistics tab is on screen:
/// loads when the tab becomes visible, re-polls every [_pollInterval] so the
/// 24-hour window keeps rolling, and reloads on pumping push notifications.
/// Nothing is fetched while the tab is hidden.
class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit(this._repository) : super(const StatisticsState()) {
    _pushSubscription = NotificationService.instance.notificationStream.listen(
      _onPush,
    );
  }

  final IDashboardRepository _repository;
  StreamSubscription<RemoteMessage>? _pushSubscription;
  Timer? _poller;

  // ponytail: polling while visible; switch to a socket/SSE feed if the
  // backend ever offers one.
  static const _pollInterval = Duration(minutes: 1);

  // ponytail: aggregates the newest N schedules client-side. Replace with a
  // backend stats endpoint if one ships, or raise N if a region outgrows it.
  static const _sampleSize = 500;

  bool get _isVisible => _poller != null;

  void setVisible({required bool visible}) {
    if (visible == _isVisible) return;
    _poller?.cancel();
    _poller = null;
    if (!visible) return;
    _poller = Timer.periodic(_pollInterval, (_) => unawaited(load()));
    unawaited(load());
  }

  void _onPush(RemoteMessage message) {
    final type = (message.data['type'] ?? '').toString().toUpperCase();
    if (_isVisible && pumpingChangeTypes.contains(type)) unawaited(load());
  }

  Future<void> load() async {
    if (state.isLoading) return;
    emit(
      StatisticsState(
        stats: state.stats,
        updatedAt: state.updatedAt,
        isLoading: true,
      ),
    );

    // Newest first so the recent past and next 24h are what fits in the page.
    final result = await _repository.getSchedules(
      sort: 'plannedStartAt,desc',
      size: _sampleSize,
    );
    if (isClosed) return;

    result.fold(
      (f) => emit(
        StatisticsState(
          stats: state.stats,
          updatedAt: state.updatedAt,
          errorMessage: f.errMessage,
        ),
      ),
      (schedules) {
        final now = DateTime.now();
        emit(
          StatisticsState(
            stats: ScheduleStats.fromSchedules(schedules, now),
            updatedAt: now,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _poller?.cancel();
    unawaited(_pushSubscription?.cancel());
    return super.close();
  }
}

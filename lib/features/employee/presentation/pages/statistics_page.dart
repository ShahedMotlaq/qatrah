import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/theme/app_colors.dart';
import 'package:qatrah/core/utils/formatting_service.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/app_failure_view.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_stats.dart';
import 'package:qatrah/features/employee/presentation/bloc/statistics_cubit.dart';
import 'package:qatrah/features/employee/presentation/widgets/stat_card_widget.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_bloc.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Navbar tab showing pumping statistics for the rolling 24-hour cycle.
/// Data only loads and live-refreshes while this tab is the visible one.
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({required this.tabIndex, super.key});

  /// This page's position in the navbar, used to know when it's on screen.
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<StatisticsCubit>()
        ..setVisible(
          visible: context.read<NavbarBloc>().state.currentTabIndex == tabIndex,
        ),
      child: BlocListener<NavbarBloc, NavbarState>(
        listenWhen: (p, c) => p.currentTabIndex != c.currentTabIndex,
        listener: (context, state) => context
            .read<StatisticsCubit>()
            .setVisible(visible: state.currentTabIndex == tabIndex),
        child: Scaffold(
          appBar: QatrahAppBarWidget(title: Text(context.l10n.statistics)),
          body: const AppBackground(child: _StatisticsBody()),
        ),
      ),
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocBuilder<StatisticsCubit, StatisticsState>(
      builder: (context, state) {
        final cubit = context.read<StatisticsCubit>();

        if (state.stats == null && state.errorMessage != null) {
          return AppFailureView(
            message: state.errorMessage == 'errorFetchingDashboardTables'
                ? l10n.errorFetchingDashboardTables
                : l10n.errorOccurred,
            onRetry: cubit.load,
          );
        }

        final stats = state.stats ?? const ScheduleStats();
        final updatedAt = state.updatedAt;

        return RefreshIndicator(
          onRefresh: cubit.load,
          child: Skeletonizer(
            enabled: state.stats == null,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              // Bottom inset clears the floating navbar (80.h + margins).
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
              children: [
                if (updatedAt != null)
                  Text(
                    l10n.lastUpdatedAt(FormattingService.formatTime(updatedAt)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                _Section(
                  title: l10n.rightNow,
                  children: [
                    _pair(
                      StatCardWidget(
                        title: l10n.activePumping,
                        count: '${stats.active}',
                        color: AppColors.success,
                      ),
                      StatCardWidget(
                        title: l10n.pausedPumping,
                        count: '${stats.paused}',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                _Section(
                  title: l10n.last24Hours,
                  children: [
                    _pair(
                      StatCardWidget(
                        title: l10n.completed,
                        count: '${stats.completed}',
                        color: theme.colorScheme.primary,
                      ),
                      StatCardWidget(
                        title: l10n.cancelled,
                        count: '${stats.cancelled}',
                        color: AppColors.error,
                      ),
                    ),
                    12.verticalSpace,
                    StatCardWidget(
                      title: l10n.pumpingTime,
                      count: stats.pumpingTime == Duration.zero
                          ? l10n.durationHours(0)
                          : FormattingService.formatDuration(
                              l10n,
                              stats.pumpingTime,
                            ),
                      color: AppColors.info,
                    ),
                  ],
                ),
                _Section(
                  title: l10n.next24Hours,
                  children: [
                    StatCardWidget(
                      title: l10n.scheduled,
                      count: '${stats.upcoming}',
                      color: const Color(0xFF1C2786),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _pair(Widget a, Widget b) => Row(
    children: [
      Expanded(child: a),
      12.horizontalSpace,
      Expanded(child: b),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
          ),
          10.verticalSpace,
          ...children,
        ],
      ),
    );
  }
}

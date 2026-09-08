import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/app_empty_state_widget.dart';
import 'package:qatrah/core/widgets/app_failure_view.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/features/water_feedback/domain/entities/water_feedback_entity.dart';
import 'package:qatrah/features/water_feedback/presentation/bloc/water_feedback_bloc.dart';
import 'package:qatrah/features/water_feedback/presentation/bloc/water_feedback_state.dart';
import 'package:qatrah/features/water_feedback/presentation/widgets/feedback_history_item.dart';
import 'package:qatrah/features/water_feedback/presentation/widgets/water_feedback_card_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:qatrah/core/services/toast_service.dart';

/// "My Evaluations" page, split into two tabs:
///  * **Unrated** — the pumping schedule(s) still awaiting the citizen's
///    rating (the same green card used on the home screen).
///  * **Rated** — the history of evaluations the citizen already submitted.
class MyFeedbackPage extends StatefulWidget {
  const MyFeedbackPage({super.key});

  @override
  State<MyFeedbackPage> createState() => _MyFeedbackPageState();
}

class _MyFeedbackPageState extends State<MyFeedbackPage> {
  late final WaterFeedbackCubit _historyCubit;
  late final WaterFeedbackCubit _eligibleFeedbackCubit;

  @override
  void initState() {
    super.initState();
    _historyCubit = getIt<WaterFeedbackCubit>()..getHistory();
    _eligibleFeedbackCubit = getIt<WaterFeedbackCubit>()..checkActiveSchedule();
  }

  @override
  void dispose() {
    _historyCubit.close();
    _eligibleFeedbackCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: QatrahAppBarWidget(
          title: Text(l10n.myEvaluations),
        ),
        body: AppBackground(
          // Submitting a rating from the "unrated" tab must refresh the
          // history tab so the new entry shows up there.
          child: BlocListener<WaterFeedbackCubit, WaterFeedbackState>(
            bloc: _eligibleFeedbackCubit,
            listener: (context, state) {
              if (state is WaterFeedbackSubmittedSuccess) {
                getIt<ToastService>().showSuccess(
                  l10n.feedbackSubmittedSuccessfully,
                );
                _historyCubit.getHistory();
              }
            },
            child: Column(
              children: [
                24.verticalSpace,
                // Tab bar styled identically to the Complaints page tab bar.
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 0,
                    dividerHeight: 0,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    labelColor: theme.colorScheme.onPrimary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5),
                    labelPadding: const EdgeInsets.symmetric(vertical: 7),
                    tabs: [
                      _FeedbackTab(
                        icon: HugeIcons.strokeRoundedClock01,
                        label: l10n.evaluationsUnratedTab,
                      ),
                      _FeedbackTab(
                        icon: HugeIcons.strokeRoundedTaskDone01,
                        label: l10n.evaluationsRatedTab,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _UnratedTab(cubit: _eligibleFeedbackCubit),
                      _RatedTab(cubit: _historyCubit),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab label: icon + text, mirroring ComplaintTabWidget ────────────────────

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab({required this.icon, required this.label});

  final List<List<dynamic>> icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final inheritedIconColor = IconTheme.of(context).color;

    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppIconWidget(
            applyPadding: false,
            icon: icon,
            color: inheritedIconColor,
          ),
          4.verticalSpace,
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Unrated tab: the schedule awaiting the citizen's rating ─────────────────

class _UnratedTab extends StatelessWidget {
  const _UnratedTab({required this.cubit});

  final WaterFeedbackCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RefreshIndicator(
      onRefresh: cubit.checkActiveSchedule,
      child: BlocBuilder<WaterFeedbackCubit, WaterFeedbackState>(
        bloc: cubit,
        builder: (context, state) {
          if (state is WaterFeedbackLoading || state is WaterFeedbackInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WaterFeedbackError) {
            return _scrollable(
              AppFailureView(
                message: state.message,
                onRetry: cubit.checkActiveSchedule,
              ),
            );
          }

          final eligible =
              state is WaterFeedbackStatusLoaded &&
              state.status.hasActiveSchedule &&
              cubit.canSubmitFeedback(state.status);

          if (!eligible) {
            return _scrollable(
              AppEmptyState(
                message: l10n.noPendingEvaluations,
                icon: HugeIcons.strokeRoundedClock01,
              ),
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            children: [
              BlocProvider.value(
                value: cubit,
                child: const WaterFeedbackCardWidget(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Wraps a non-scrolling child so pull-to-refresh still works when the tab
  /// is "empty" (error / empty state).
  Widget _scrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}

// ── Rated tab: history of submitted evaluations ─────────────────────────────

class _RatedTab extends StatelessWidget {
  const _RatedTab({required this.cubit});

  final WaterFeedbackCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RefreshIndicator(
      onRefresh: cubit.getHistory,
      child: BlocBuilder<WaterFeedbackCubit, WaterFeedbackState>(
        bloc: cubit,
        builder: (context, state) {
          if (state is WaterFeedbackLoading || state is WaterFeedbackInitial) {
            return _buildShimmerLoading();
          }

          if (state is WaterFeedbackError) {
            return _scrollable(
              AppFailureView(
                message: state.message,
                onRetry: cubit.getHistory,
              ),
            );
          }

          if (state is WaterFeedbackHistoryLoaded) {
            final history = state.history;

            if (history.isEmpty) {
              return _scrollable(
                AppEmptyState(
                  message: l10n.noPreviousEvaluations,
                  icon: HugeIcons.strokeRoundedFileSearch,
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              itemCount: history.length,
              separatorBuilder: (_, _) => 10.verticalSpace,
              itemBuilder: (context, index) =>
                  FeedbackHistoryItemWidget(item: history[index]),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    final shimmerItems = List.generate(
      5,
      (_) => WaterFeedbackEntity(
        id: 0,
        feedbackType: 'WATER_RECEIVED',
        schedulePath: 'ــــــــــــــــــــــــــــــ',
        createdAt: DateTime.now(),
      ),
    );

    return Skeletonizer(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        itemCount: shimmerItems.length,
        separatorBuilder: (_, _) => 10.verticalSpace,
        itemBuilder: (context, index) =>
            FeedbackHistoryItemWidget(item: shimmerItems[index]),
      ),
    );
  }

  Widget _scrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}

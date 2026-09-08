import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/network/network_status_cubit.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/core/widgets/offline_banner_widget.dart';
import 'package:qatrah/core/widgets/offline_state_widget.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_event.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart';
import 'package:qatrah/features/home/presentation/widgets/area_selection_header_widget.dart';
import 'package:qatrah/features/home/presentation/widgets/home_header_widget.dart';
import 'package:qatrah/features/home/presentation/widgets/main_content_switcher_widget.dart';
import 'package:qatrah/features/home/presentation/widgets/upcoming_schedules_widget.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_bloc.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_state.dart';
import 'package:qatrah/features/water_feedback/presentation/bloc/water_feedback_bloc.dart';
import 'package:qatrah/features/water_feedback/presentation/bloc/water_feedback_state.dart';
import 'package:qatrah/features/water_feedback/presentation/widgets/water_feedback_card_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:qatrah/core/services/toast_service.dart';

/// The main landing page of the app.
///
/// Coordinates [HomeBloc], [WaterFeedbackCubit] and [NetworkStatusCubit]
/// to display the current pumping status, upcoming schedules and location
/// selection UI.
///
/// **Smart refresh behaviour:**
/// * First launch → full-page shimmer while data loads.
/// * Switching back from another tab → small bouncing icon animation in the
///   header while data refreshes silently in the background.
class HomePage extends StatefulWidget {
  const HomePage({
    this.notificationExtra,
    super.key,
  });

  final Map<String, dynamic>? notificationExtra;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _hasVisibleContent(HomeState state) {
    return state.filteredLocationName != null ||
        state.monitoredAreas.isNotEmpty ||
        state.pumpingStatus.isNotEmpty ||
        state.schedules.isNotEmpty ||
        state.user != null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (context) => getIt<HomeBloc>()..add(LoadHomeDataEvent()),
        ),
        BlocProvider<WaterFeedbackCubit>(
          create: (context) =>
              getIt<WaterFeedbackCubit>()..checkActiveSchedule(),
        ),
      ],
      child: Builder(
        builder: (context) {
          if (widget.notificationExtra != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<HomeBloc>().add(
                NavigateFromNotificationEvent(
                  scheduleId: widget.notificationExtra!['scheduleId'] as int?,
                  regionName:
                      widget.notificationExtra!['regionName'] as String?,
                  unitName: widget.notificationExtra!['unitName'] as String?,
                  neighborhoodName:
                      widget.notificationExtra!['neighborhoodName'] as String?,
                  zoneName: widget.notificationExtra!['zoneName'] as String?,
                ),
              );
            });
          }

          return _NavbarTabListener(
            child: _HomeListeners(
              child: Scaffold(
                appBar: QatrahAppBarWidget(
                  title: Text(context.l10n.home),
                ),
                body: AppBackground(
                  child: _HomeBody(hasVisibleContent: _hasVisibleContent),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Navbar tab switch listener (triggers silent refresh with debounce) ───────

class _NavbarTabListener extends StatefulWidget {
  const _NavbarTabListener({required this.child});

  final Widget child;

  @override
  State<_NavbarTabListener> createState() => _NavbarTabListenerState();
}

class _NavbarTabListenerState extends State<_NavbarTabListener> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NavbarBloc is only available when HomePage lives inside NavbarPage.
    // When the user navigates directly to HomePage (deep-link) we safely
    // fall back to the plain child.
    NavbarBloc? navbarBloc;
    try {
      navbarBloc = context.read<NavbarBloc>();
    } catch (_) {
      navbarBloc = null;
    }

    if (navbarBloc == null) return widget.child;

    return BlocListener<NavbarBloc, NavbarState>(
      bloc: navbarBloc,
      listenWhen: (prev, curr) =>
          prev.currentTabIndex != 0 && curr.currentTabIndex == 0,
      listener: (context, state) {
        final homeBloc = context.read<HomeBloc>();
        final homeState = homeBloc.state;

        // Only silently refresh if we already loaded data once and we are
        // not currently busy.
        if (!homeState.isFirstLoad &&
            !homeState.isRefreshing &&
            !homeState.isLoading) {
          // Debounce: if the user rapidly taps the home tab, cancel the
          // previous timer and start a new one. The refresh only fires
          // after 500 ms of inactivity.
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 500), () {
            if (mounted) {
              homeBloc.add(SilentRefreshHomeDataEvent());
            }
          });
        }
      },
      child: widget.child,
    );
  }
}

// ── Bloc listeners ────────────────────────────────────────────────────────────

class _HomeListeners extends StatelessWidget {
  const _HomeListeners({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiBlocListener(
      listeners: [
        BlocListener<NetworkStatusCubit, NetworkStatusState>(
          listenWhen: (prev, next) =>
              !next.isInitial && !next.isChecking && prev.status != next.status,
          listener: (context, networkState) {
            if (networkState.isOffline) {
              getIt<ToastService>().showError(l10n.internetDisconnected);
            } else if (networkState.isOnline) {
              getIt<ToastService>().showSuccess(l10n.internetRestored);
            }
          },
        ),
        BlocListener<WaterFeedbackCubit, WaterFeedbackState>(
          listener: (context, state) {
            if (state is WaterFeedbackSubmittedSuccess) {
              getIt<ToastService>().showSuccess(
                l10n.feedbackSubmittedSuccessfully,
              );
            }
          },
        ),
        BlocListener<HomeBloc, HomeState>(
          listenWhen: (prev, curr) => prev.pumpingStatus != curr.pumpingStatus,
          listener: (context, state) {
            context.read<WaterFeedbackCubit>().checkActiveSchedule();
          },
        ),
      ],
      child: child,
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.hasVisibleContent});

  final bool Function(HomeState state) hasVisibleContent;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkStatusCubit, NetworkStatusState>(
      builder: (context, networkState) {
        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            final showOfflineState =
                networkState.isOffline &&
                !homeState.isLoading &&
                !hasVisibleContent(homeState);

            if (showOfflineState) {
              return OfflineStateWidget(
                isRetrying: networkState.isRechecking,
                onRetry: () {
                  context.read<NetworkStatusCubit>().recheckConnection();
                  context.read<HomeBloc>().add(LoadHomeDataEvent());
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NetworkStatusCubit>().recheckConnection();
                context.read<HomeBloc>().add(RefreshHomeDataEvent());
                await context.read<WaterFeedbackCubit>().checkActiveSchedule();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (networkState.isOffline && hasVisibleContent(homeState))
                    const SliverToBoxAdapter(
                      child: OfflineBannerWidget(),
                    ),
                  SliverToBoxAdapter(child: 10.verticalSpace),
                  const SliverToBoxAdapter(
                    child: HomeHeaderWidget(),
                  ),
                  SliverToBoxAdapter(
                    child: Skeletonizer(
                      enabled: homeState.isLoading,
                      child: AreaSelectionHeaderWidget(
                        isRefreshing: homeState.isRefreshing,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    // Home surfaces only the active (green) pumping rating.
                    // Past/completed ratings live in the "unrated" tab of the
                    // My Evaluations page.
                    child: WaterFeedbackCardWidget(includeCompleted: false),
                  ),
                  SliverToBoxAdapter(child: 10.verticalSpace),
                  SliverToBoxAdapter(
                    child: Skeletonizer(
                      enabled: homeState.isLoading,
                      child: const MainContentSwitcherWidget(),
                    ),
                  ),
                  SliverToBoxAdapter(child: 14.verticalSpace),
                  SliverToBoxAdapter(
                    child: Skeletonizer(
                      enabled: homeState.isLoading,
                      child: const UpcomingSchedulesWidget(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

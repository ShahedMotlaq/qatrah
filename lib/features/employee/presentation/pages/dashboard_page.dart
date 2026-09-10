import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/app_loading_widget.dart';
import 'package:qatrah/core/widgets/app_toast.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_event.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';
import 'package:qatrah/features/employee/presentation/widgets/active_pumping_cards_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/dashboard_filter_button_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/dashboard_reset_filters_fab_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/dashboard_section_header_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/dashboard_table_list_widget.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => getIt<DashboardBloc>()..add(LoadDashboardData()),
      child: BlocListener<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            AppToast.show(
              context: context,
              message: _mapDashboardErrorMessage(
                state.errorMessage!,
                context.l10n,
              ),
              type: AppToastType.error,
            );
          }
        },
        child: Builder(
          builder: (innerContext) => Scaffold(
            appBar: QatrahAppBarWidget(
              title: Text(l10n.dashboard),
              actions: const [DashboardFilterButtonWidget()],
            ),
            // The navbar shell extends its body behind the bottom bar, so lift
            // the FAB clear of it (bar 80.h + 8 margin top and bottom).
            floatingActionButton: Padding(
              padding: EdgeInsets.only(bottom: 96.h),
              child: const DashboardResetFiltersFabWidget(),
            ),
            body: AppBackground(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      innerContext.read<DashboardBloc>().add(
                        RefreshSchedulesEvent(),
                      );
                    },
                    child: CustomScrollView(
                      slivers: [
                        SliverList(
                          delegate: SliverChildListDelegate.fixed([
                            14.verticalSpace,
                            // البطاقات الجديدة (الخضراء والبرتقالية) في الأعلى
                            const ActiveAndNextPumpingCardsWidget(),
                            14.verticalSpace,
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                // Filters moved into the AppBar sheet.
                                child: const DashboardSectionHeaderWidget(),
                              ),
                            ),
                            14.verticalSpace,
                          ]),
                        ),
                        const DashboardTableListWidget(),
                      ],
                    ),
                  ),
                  BlocBuilder<DashboardBloc, DashboardState>(
                    buildWhen: (p, c) => p.isLoading != c.isLoading,
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const ColoredBox(
                          color: Colors.black26,
                          child: Center(
                            child: AppLoadingWidget(size: 60),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _mapDashboardErrorMessage(String message, AppLocalizations l10n) {
    final normalized = message.trim().toLowerCase();
    if (normalized.contains('401') ||
        normalized.contains('403') ||
        normalized.contains('unauthorized') ||
        normalized.contains('forbidden') ||
        normalized == 'forbidden') {
      return l10n.forbidden;
    }
    switch (message.trim()) {
      case 'startDateMustBeInFuture':
        return l10n.startDateMustBeInFuture;
      case 'cannotStartBeforeScheduledTime':
        return l10n.cannotStartBeforeScheduledTime;
      case 'endDateMustBeAfterStart':
        return l10n.endDateMustBeAfterStart;
      case 'noAssignedUnitsCannotAddSchedule':
        return l10n.noAssignedUnitsCannotAddSchedule;
      case 'errorFetchingDashboardTables':
        return l10n.errorFetchingDashboardTables;
      case 'errorFetchingRegions':
        return l10n.errorFetchingRegions;
      case 'errorCreatingSchedule':
        return l10n.errorCreatingSchedule;
      case 'errorStartingPumping':
        return l10n.errorStartingPumping;
      case 'errorEndingPumping':
        return l10n.errorEndingPumping;
      case 'errorCancellingSchedule':
        return l10n.errorCancellingSchedule;
      case 'errorUpdatingSchedule':
        return l10n.errorUpdatingSchedule;
    }
    return l10n.errorOccurred;
  }
}

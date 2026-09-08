import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';
import 'package:qatrah/features/employee/presentation/widgets/stat_card_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DashboardStatsGridWidget extends StatelessWidget {
  const DashboardStatsGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (p, c) =>
          p.isLoading != c.isLoading ||
          p.totalSchedules != c.totalSchedules ||
          p.activePumping != c.activePumping ||
          p.scheduledPumping != c.scheduledPumping ||
          p.pausedPumping != c.pausedPumping,
      builder: (context, state) {
        return Skeletonizer(
          enabled: state.isLoading,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCardWidget(
                        title: l10n.totalSchedules,
                        count: state.totalSchedules.toString(),
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    12.horizontalSpace,
                    Expanded(
                      child: StatCardWidget(
                        title: l10n.activePumping,
                        count: state.activePumping.toString(),
                        color: const Color(0xFF32A852),
                      ),
                    ),
                  ],
                ),
                12.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: StatCardWidget(
                        title: l10n.scheduled,
                        count: state.scheduledPumping.toString(),
                        color: const Color(0xFF1C2786),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: StatCardWidget(
                        title: l10n.pausedPumping,
                        count: state.pausedPumping.toString(),
                        color: const Color(0xFFF5A623),
                      ),
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
}

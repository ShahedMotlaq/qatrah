import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_event.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';

/// Shortcut out of a filtered list: only shown while a filter is active, and
/// clears every filter without reopening the filter sheet.
class DashboardResetFiltersFabWidget extends StatelessWidget {
  const DashboardResetFiltersFabWidget({super.key});

  void _reset(BuildContext context) {
    context.read<DashboardBloc>()
      ..add(ResetFilters())
      // Filters are also part of the query the API is asked for, so refetch
      // rather than only re-filtering what is already loaded.
      ..add(LoadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (p, c) => p.activeFilterCount != c.activeFilterCount,
      builder: (context, state) {
        if (state.activeFilterCount == 0) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          heroTag: 'dashboardResetFilters',
          onPressed: () => _reset(context),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          icon: AppIconWidget(
            icon: HugeIcons.strokeRoundedFilterRemove,
            color: theme.colorScheme.onPrimary,
            size: 20,
            applyPadding: false,
          ),
          label: Text(l10n.resetFilter),
        );
      },
    );
  }
}

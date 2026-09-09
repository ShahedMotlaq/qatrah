import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/appdialog/showApp_bottom_sheet_widget.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';
import 'package:qatrah/features/employee/presentation/widgets/dashboard_filters_widget.dart';

/// AppBar action that opens the filter sheet, badged with the number of
/// filters currently narrowing the list.
class DashboardFilterButtonWidget extends StatelessWidget {
  const DashboardFilterButtonWidget({super.key});

  Future<void> _openFilters(BuildContext context) {
    // The sheet is built on the Navigator overlay, outside this page's
    // provider, so hand the bloc down explicitly.
    final bloc = context.read<DashboardBloc>();
    final l10n = context.l10n;
    return showAppBottomSheet(
      context: context,
      title: l10n.filter,
      titleIcon: const AppIconWidget(icon: HugeIcons.strokeRoundedFilter),
      content: BlocProvider.value(
        value: bloc,
        child: const DashboardFiltersWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (p, c) => p.activeFilterCount != c.activeFilterCount,
      builder: (context, state) {
        final count = state.activeFilterCount;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Badge.count(
            count: count,
            isLabelVisible: count > 0,
            child: TextButton.icon(
              onPressed: () => _openFilters(context),
              icon: AppIconWidget(
                icon: HugeIcons.strokeRoundedFilter,
                color: theme.colorScheme.secondary,
                size: 20,
                applyPadding: false,
              ),
              label: Text(l10n.filter),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
                textStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

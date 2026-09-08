import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/core/widgets/formField_wrappers/app_data_picker_widget.dart';
import 'package:qatrah/core/widgets/formField_wrappers/app_dropdown_widget.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_event.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';

class DashboardStatusDateFiltersWidget extends StatelessWidget {
  const DashboardStatusDateFiltersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return Column(
          children: [
            AppDropdownField<String>(
              prefixIcon: const AppIconWidget(
                icon: HugeIcons.strokeRoundedFilter,
              ),
              hintText: l10n.filterByPumpingStatus,
              items: const [
                'ALL',
                'ACTIVE',
                'SCHEDULED',
                'COMPLETED',
                'CANCELLED',
              ],
              value: state.selectedStatus,
              itemLabel: (val) {
                switch (val) {
                  case 'ALL':
                    return l10n.all;
                  case 'ACTIVE':
                    return l10n.active;
                  case 'SCHEDULED':
                    return l10n.scheduled;
                  case 'COMPLETED':
                    return l10n.finished;
                  case 'CANCELLED':
                    return l10n.cancelled;
                  default:
                    return val;
                }
              },
              onChanged: (val) {
                context.read<DashboardBloc>().add(FilterStatusChanged(val));
              },
            ),
            12.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: AppDatePickerField(
                    hintText: l10n.fromDate,
                    value: state.fromDate,
                    showTimePicker: false,
                    onChanged: (newDate) {
                      context.read<DashboardBloc>().add(
                        FilterFromDateChanged(newDate),
                      );
                    },
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: AppDatePickerField(
                    hintText: l10n.toDate,
                    value: state.toDate,
                    showTimePicker: false,
                    onChanged: (newDate) {
                      context.read<DashboardBloc>().add(
                        FilterToDateChanged(newDate),
                      );
                    },
                  ),
                ),
              ],
            ),
            16.verticalSpace,
            if (state.selectedRegion != null ||
                state.selectedUnit != null ||
                state.selectedNeighborhood != null ||
                state.selectedZone != null ||
                (state.selectedStatus != null &&
                    state.selectedStatus != 'ALL') ||
                state.fromDate != null ||
                state.toDate != null)
              AppButton(
                onPressed: () {
                  context.read<DashboardBloc>().add(ResetFilters());
                },
                text: l10n.resetFilter,
                backgroundColor: theme.colorScheme.surface,
                icon: const AppIconWidget(
                  icon: HugeIcons.strokeRoundedConfiguration02,
                ),
              ),
          ],
        );
      },
    );
  }
}

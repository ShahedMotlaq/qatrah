import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/formField_wrappers/app_data_picker_widget.dart';
import 'package:qatrah/core/widgets/formField_wrappers/app_dropdown_widget.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_event.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';

class DashboardStatusDateFiltersWidget extends StatelessWidget {
  const DashboardStatusDateFiltersWidget({super.key});

  static const _statuses = [
    'ALL',
    'ACTIVE',
    'SCHEDULED',
    'PAUSED',
    'COMPLETED',
    'CANCELLED',
  ];

  String _statusLabel(String value, BuildContext context) {
    final l10n = context.l10n;
    switch (value) {
      case 'ALL':
        return l10n.all;
      case 'ACTIVE':
        return l10n.active;
      case 'SCHEDULED':
        return l10n.scheduled;
      case 'PAUSED':
        return l10n.pausedStatus;
      case 'COMPLETED':
        return l10n.finished;
      case 'CANCELLED':
        return l10n.cancelled;
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final bloc = context.read<DashboardBloc>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDropdownField<String>(
              prefixIcon: const AppIconWidget(
                icon: HugeIcons.strokeRoundedFilter,
              ),
              hintText: l10n.filterByPumpingStatus,
              items: _statuses,
              value: state.selectedStatus,
              itemLabel: (val) => _statusLabel(val, context),
              onChanged: (val) => bloc.add(FilterStatusChanged(val)),
            ),
            12.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: AppDatePickerField(
                    hintText: l10n.fromDate,
                    value: state.fromDate,
                    showTimePicker: false,
                    // History is the point of a date filter — past dates must
                    // be selectable, unlike the schedule creation form.
                    allowPastDates: true,
                    onChanged: (newDate) =>
                        bloc.add(FilterFromDateChanged(newDate)),
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: AppDatePickerField(
                    hintText: l10n.toDate,
                    value: state.toDate,
                    showTimePicker: false,
                    allowPastDates: true,
                    onChanged: (newDate) =>
                        bloc.add(FilterToDateChanged(newDate)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

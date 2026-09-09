import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/utils/user_helper.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_toast.dart';
import 'package:qatrah/core/widgets/appdialog/showApp_bottom_sheet_widget.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/widgets/add_schedule_dialog_widget.dart';

class DashboardSectionHeaderWidget extends StatelessWidget {
  const DashboardSectionHeaderWidget({super.key});

  Future<void> showAddScheduleSheet(BuildContext context) {
    final dashboardBloc = context.read<DashboardBloc>();
    return showAppBottomSheet(
      context: context,
      content: BlocProvider.value(
        value: dashboardBloc,
        child: const AddScheduleDialogWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        // Full radius: the filter panel that used to sit under this header
        // now lives in the AppBar sheet, so the header is the whole card.
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AppIconWidget(
                icon: HugeIcons.strokeRoundedWaterPump,
                color: theme.colorScheme.secondary,
              ),
              Text(
                l10n.schedules,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final isOperator = await UserHelper.isOperator();
              final isAdmin = await UserHelper.isAdmin();
              if (isOperator && !isAdmin) {
                final assigned = await UserHelper.getAssignedUnitIds();
                if (assigned.isEmpty) {
                  if (!context.mounted) return;
                  AppToast.show(
                    context: context,
                    message: context.l10n.noAssignedUnitsCannotAddSchedule,
                    type: AppToastType.error,
                  );
                  return;
                }
              }
              if (!context.mounted) return;
              await showAddScheduleSheet(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 46),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              backgroundColor: theme.colorScheme.secondary.withValues(
                alpha: 0.15,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            icon: AppIconWidget(
              applyPadding: false,
              icon: HugeIcons.strokeRoundedAdd01,
              color: theme.colorScheme.secondary,
              size: 14,
            ),
            label: Text(
              l10n.addNewSchedule,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/appdialog/showApp_bottom_sheet_widget.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/widgets/edit_schedule_dialog_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/schedule_confirmation_dialogs.dart';
import 'package:qatrah/features/employee/presentation/widgets/shift_schedule_dialog_widget.dart';

class ScheduleTableActionCellWidget extends StatelessWidget {
  const ScheduleTableActionCellWidget({
    required this.status,
    required this.scheduleId,
    required this.schedule,
    super.key,
  });

  final String status;
  final int scheduleId;
  final ScheduleEntity schedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final upperStatus = status.toUpperCase();

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (upperStatus == 'SCHEDULED') ...[
          _ActionTextButton(
            label: l10n.startPumping,
            icon: HugeIcons.strokeRoundedPlay,
            color: const Color(0xFF1B4D3E),
            onPressed: () => ScheduleConfirmationDialogs.showStartConfirmation(
              context,
              scheduleId: scheduleId,
            ),
          ),
          _ActionTextButton(
            label: l10n.edit,
            icon: HugeIcons.strokeRoundedPencilEdit01,
            color: const Color(0xFF1565C0),
            onPressed: () => _showEditDialog(context),
          ),
          _ActionTextButton(
            label: l10n.shiftSchedule,
            icon: HugeIcons.strokeRoundedClock01,
            color: const Color(0xFF6A1B9A),
            onPressed: () => _showShiftDialog(context),
          ),
          _ActionTextButton(
            label: l10n.cancel,
            icon: HugeIcons.strokeRoundedCancel01,
            color: theme.colorScheme.error,
            onPressed: () => ScheduleConfirmationDialogs.showCancelConfirmation(
              context,
              scheduleId: scheduleId,
            ),
          ),
        ] else if (upperStatus == 'ACTIVE') ...[
          _ActionTextButton(
            label: l10n.pausePumping,
            icon: HugeIcons.strokeRoundedPause,
            color: const Color(0xFFF5A623),
            onPressed: () => ScheduleConfirmationDialogs.showPauseConfirmation(
              context,
              scheduleId: scheduleId,
            ),
          ),
          _ActionTextButton(
            label: l10n.endPumping,
            icon: HugeIcons.strokeRoundedStop,
            color: const Color(0xFFE65100),
            onPressed: () => ScheduleConfirmationDialogs.showEndConfirmation(
              context,
              scheduleId: scheduleId,
            ),
          ),
        ] else if (upperStatus == 'PAUSED') ...[
          _ActionTextButton(
            label: l10n.resumePumping,
            icon: HugeIcons.strokeRoundedPlay,
            color: const Color(0xFF1B4D3E),
            onPressed: () => ScheduleConfirmationDialogs.showResumeConfirmation(
              context,
              scheduleId: scheduleId,
            ),
          ),
          _ActionTextButton(
            label: l10n.shiftSchedule,
            icon: HugeIcons.strokeRoundedClock01,
            color: const Color(0xFF6A1B9A),
            onPressed: () => _showShiftDialog(context),
          ),
          _ActionTextButton(
            label: l10n.endPumping,
            icon: HugeIcons.strokeRoundedStop,
            color: const Color(0xFFE65100),
            onPressed: () => ScheduleConfirmationDialogs.showEndConfirmation(
              context,
              scheduleId: scheduleId,
            ),
          ),
        ],
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final bloc = context.read<DashboardBloc>();
    showAppBottomSheet(
      context: context,
      content: BlocProvider.value(
        value: bloc,
        child: EditScheduleDialogWidget(schedule: schedule),
      ),
    );
  }

  void _showShiftDialog(BuildContext context) {
    final bloc = context.read<DashboardBloc>();
    showAppBottomSheet(
      context: context,
      content: BlocProvider.value(
        value: bloc,
        child: ShiftScheduleDialogWidget(schedule: schedule),
      ),
    );
  }
}

class _ActionTextButton extends StatelessWidget {
  const _ActionTextButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.labelSmall?.copyWith(
      color: color,
      fontSize: 11.sp,
      fontWeight: FontWeight.w600,
    );
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.08),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        textStyle: baseStyle,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconWidget(
            icon: icon,
            color: color,
            size: 14,
            applyPadding: false,
          ),
          4.horizontalSpace,
          Text(label, style: baseStyle),
        ],
      ),
    );
  }
}

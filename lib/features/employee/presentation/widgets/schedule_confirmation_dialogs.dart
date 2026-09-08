import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/core/widgets/appdialog/dynamic_confirm_dialog.dart';
import 'package:qatrah/core/widgets/appdialog/showApp_bottom_sheet_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_event.dart';

class ScheduleConfirmationDialogs {
  const ScheduleConfirmationDialogs._();

  static Future<void> showStartConfirmation(
    BuildContext context, {
    required int scheduleId,
  }) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => DynamicConfirmDialog(
        title: l10n.confirmation,
        message: l10n.startPumpingConfirmationMessage,
        cancelBtnText: l10n.no,
        confirmBtnText: l10n.yes,
        onConfirm: () {
          context.read<DashboardBloc>().add(StartScheduleEvent(scheduleId));
        },
      ),
    );
  }

  static Future<void> showEndConfirmation(
    BuildContext context, {
    required int scheduleId,
  }) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => DynamicConfirmDialog(
        title: l10n.confirmation,
        message: l10n.endPumpingConfirmationMessage,
        cancelBtnText: l10n.no,
        confirmBtnText: l10n.yes,
        onConfirm: () {
          context.read<DashboardBloc>().add(EndScheduleEvent(scheduleId));
        },
      ),
    );
  }

  static Future<void> showPauseConfirmation(
    BuildContext context, {
    required int scheduleId,
  }) async {
    // The modal bottom sheet is built on the Navigator overlay, so it does not
    // inherit this page's DashboardBloc provider. Capture the bloc here and
    // re-expose it to the sheet, or context.read inside _submit would throw
    // ProviderNotFoundException and the "Yes" button would do nothing.
    final bloc = context.read<DashboardBloc>();
    await showAppBottomSheet(
      context: context,
      content: BlocProvider.value(
        value: bloc,
        child: _PauseScheduleReasonSheet(scheduleId: scheduleId),
      ),
    );
  }

  static Future<void> showResumeConfirmation(
    BuildContext context, {
    required int scheduleId,
  }) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => DynamicConfirmDialog(
        title: l10n.confirmation,
        message: l10n.resumePumpingConfirmationMessage,
        cancelBtnText: l10n.no,
        confirmBtnText: l10n.yes,
        onConfirm: () {
          context.read<DashboardBloc>().add(ResumeScheduleEvent(scheduleId));
        },
      ),
    );
  }

  static Future<void> showCancelConfirmation(
    BuildContext context, {
    required int scheduleId,
  }) async {
    // Same as pause: re-expose the bloc to the modal sheet's subtree so the
    // "Yes" button can dispatch CancelScheduleEvent.
    final bloc = context.read<DashboardBloc>();
    await showAppBottomSheet(
      context: context,
      content: BlocProvider.value(
        value: bloc,
        child: _CancelScheduleReasonSheet(scheduleId: scheduleId),
      ),
    );
  }
}

class _CancelScheduleReasonSheet extends StatefulWidget {
  const _CancelScheduleReasonSheet({required this.scheduleId});

  final int scheduleId;

  @override
  State<_CancelScheduleReasonSheet> createState() =>
      _CancelScheduleReasonSheetState();
}

class _CancelScheduleReasonSheetState
    extends State<_CancelScheduleReasonSheet> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final reason = _reasonController.text.trim();
    context.read<DashboardBloc>().add(
      CancelScheduleEvent(
        widget.scheduleId,
        cancellationReason: reason.isEmpty ? null : reason,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 8.w,
        right: 8.w,
        top: 8.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cancelScheduleConfirmationMessage,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          12.verticalSpace,
          AppTextField(
            controller: _reasonController,
            hintText: l10n.cancellationReasonLabel,
            minLines: 2,
            maxLines: 3,
          ),
          16.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: l10n.no,
                  isOutline: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: AppButton(
                  text: l10n.yes,
                  backgroundColor: theme.colorScheme.error,
                  onPressed: () => _submit(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PauseScheduleReasonSheet extends StatefulWidget {
  const _PauseScheduleReasonSheet({required this.scheduleId});

  final int scheduleId;

  @override
  State<_PauseScheduleReasonSheet> createState() =>
      _PauseScheduleReasonSheetState();
}

class _PauseScheduleReasonSheetState extends State<_PauseScheduleReasonSheet> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final reason = _reasonController.text.trim();
    context.read<DashboardBloc>().add(
      PauseScheduleEvent(
        widget.scheduleId,
        pauseReason: reason.isEmpty ? null : reason,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 8.w,
        right: 8.w,
        top: 8.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pausePumpingConfirmationMessage,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          12.verticalSpace,
          AppTextField(
            controller: _reasonController,
            hintText: l10n.pauseReasonLabel,
            minLines: 2,
            maxLines: 3,
          ),
          16.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: l10n.no,
                  isOutline: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: AppButton(
                  text: l10n.yes,
                  onPressed: () => _submit(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

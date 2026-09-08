import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/core/widgets/app_toast.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/core/widgets/formField_wrappers/app_data_picker_widget.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_event.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';

class EditScheduleDialogWidget extends StatefulWidget {
  const EditScheduleDialogWidget({
    required this.schedule,
    super.key,
  });

  final ScheduleEntity schedule;

  @override
  State<EditScheduleDialogWidget> createState() =>
      _EditScheduleDialogWidgetState();
}

class _EditScheduleDialogWidgetState extends State<EditScheduleDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startTime;
  DateTime? _endTime;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _startTime = widget.schedule.startTime;
    _endTime = widget.schedule.endTime;
    _notesController = TextEditingController(text: widget.schedule.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onConfirm(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final trimmedNotes = _notesController.text.trim();

    // If nothing actually changed, just close without calling API.
    if (trimmedNotes == (widget.schedule.notes ?? '').trim() &&
        _startTime == widget.schedule.startTime &&
        _endTime == widget.schedule.endTime) {
      Navigator.of(context).pop();
      return;
    }

    if (_startTime == null) {
      AppToast.show(
        context: context,
        message: context.l10n.selectStartTime,
        type: AppToastType.warning,
      );
      return;
    }
    if (_endTime == null) {
      AppToast.show(
        context: context,
        message: context.l10n.selectEndTime,
        type: AppToastType.warning,
      );
      return;
    }

    if (!_endTime!.isAfter(_startTime!)) {
      AppToast.show(
        context: context,
        message: context.l10n.endDateMustBeAfterStart,
        type: AppToastType.warning,
      );
      return;
    }

    context.read<DashboardBloc>().add(
      UpdateScheduleSubmitted(
        scheduleId: widget.schedule.id,
        regionId: widget.schedule.regionId,
        unitId: widget.schedule.unitId,
        neighborhoodId: widget.schedule.neighborhoodId,
        zoneId: widget.schedule.zoneId,
        start: _startTime!,
        end: _endTime!,
        notes: trimmedNotes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schedule = widget.schedule;

    return BlocConsumer<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state.isSuccess) {
          AppToast.show(
            context: context,
            message: l10n.scheduleUpdatedSuccessfully,
          );
          Navigator.of(context).pop();
        }
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          AppToast.show(
            context: context,
            message: state.errorMessage!,
            type: AppToastType.error,
          );
        }
      },
      builder: (context, state) {
        final media = MediaQuery.of(context);
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (media.size.height - media.viewInsets.bottom) * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    l10n.edit,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                16.verticalSpace,
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildReadOnlyField(
                            icon: HugeIcons.strokeRoundedBuilding03,
                            label: l10n.regionLabel,
                            value: schedule.regionName,
                          ),
                          if (schedule.unitName != null) ...[
                            10.verticalSpace,
                            _buildReadOnlyField(
                              icon: HugeIcons.strokeRoundedBuilding04,
                              label: l10n.unitLabel,
                              value: schedule.unitName!,
                            ),
                          ],
                          if (schedule.neighborhoodName != null) ...[
                            10.verticalSpace,
                            _buildReadOnlyField(
                              icon: HugeIcons.strokeRoundedCity01,
                              label: l10n.neighborhoodLabel,
                              value: schedule.neighborhoodName!,
                            ),
                          ],
                          if (schedule.zoneName != null) ...[
                            10.verticalSpace,
                            _buildReadOnlyField(
                              icon: HugeIcons.strokeRoundedMapsLocation02,
                              label: l10n.zoneLabel,
                              value: schedule.zoneName!,
                            ),
                          ],
                          10.verticalSpace,
                          AppDatePickerField(
                            hintText: l10n.startTime,
                            value: _startTime,
                            onChanged: (val) =>
                                setState(() => _startTime = val),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return l10n.selectStartTime;
                              }
                              return null;
                            },
                          ),
                          10.verticalSpace,
                          AppDatePickerField(
                            hintText: l10n.endTime,
                            value: _endTime,
                            onChanged: (val) => setState(() => _endTime = val),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return l10n.selectEndTime;
                              }
                              return null;
                            },
                          ),
                          10.verticalSpace,
                          AppTextField(
                            prefixIcon: const AppIconWidget(
                              icon: HugeIcons.strokeRoundedNote,
                            ),
                            controller: _notesController,
                            hintText: l10n.notes,
                            maxLines: 4,
                            minLines: 2,
                            keyboardType: TextInputType.multiline,
                          ),
                          16.verticalSpace,
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: l10n.cancel,
                        onPressed: state.isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        isOutline: true,
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: AppButton(
                        text: l10n.save,
                        onPressed: state.isLoading
                            ? null
                            : () => _onConfirm(context),
                        isLoading: state.isLoading,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadOnlyField({
    required List<List<dynamic>> icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          AppIconWidget(icon: icon, size: 18),
          12.horizontalSpace,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

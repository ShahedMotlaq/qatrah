import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/utils/app_date_formatter.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_toast.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_event.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';

/// Bottom-sheet dialog that delays a persistent schedule by a number of hours.
/// Both the start and end times move together (the backend keeps the same
/// schedule id), so operators can react to disruptions without re-creating it.
class ShiftScheduleDialogWidget extends StatefulWidget {
  const ShiftScheduleDialogWidget({
    required this.schedule,
    super.key,
  });

  final ScheduleEntity schedule;

  @override
  State<ShiftScheduleDialogWidget> createState() =>
      _ShiftScheduleDialogWidgetState();
}

class _ShiftScheduleDialogWidgetState extends State<ShiftScheduleDialogWidget> {
  static const _presets = [1, 2, 3, 6, 12, 24];
  static const _minHours = 1;
  static const _maxHours = 168; // one week

  int _hours = 2;

  void _setHours(int value) {
    setState(() => _hours = value.clamp(_minHours, _maxHours));
  }

  void _submit(BuildContext context) {
    context.read<DashboardBloc>().add(
      ShiftScheduleEvent(widget.schedule.id, hours: _hours),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final delay = Duration(hours: _hours);
    final newStart = widget.schedule.startTime.add(delay);
    final newEnd = widget.schedule.endTime.add(delay);

    return BlocConsumer<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state.isSuccess) {
          AppToast.show(
            context: context,
            message: l10n.scheduleShiftedSuccessfully,
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
              Center(
                child: Text(
                  l10n.shiftScheduleTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              8.verticalSpace,
              Text(
                l10n.shiftScheduleDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              16.verticalSpace,
              Text(
                l10n.shiftDurationLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              10.verticalSpace,
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final preset in _presets)
                    ChoiceChip(
                      label: Text('$preset ${l10n.hourAbbreviation}'),
                      selected: _hours == preset,
                      onSelected: (_) => _setHours(preset),
                    ),
                ],
              ),
              12.verticalSpace,
              _HoursStepper(
                hours: _hours,
                onChanged: _setHours,
                minHours: _minHours,
                maxHours: _maxHours,
              ),
              16.verticalSpace,
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.shiftNewTimingLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    6.verticalSpace,
                    _PreviewRow(
                      icon: HugeIcons.strokeRoundedClock01,
                      label: l10n.startTime,
                      value: AppDateFormatter.formatPumpingDateTime(
                        newStart,
                        context,
                      ),
                    ),
                    4.verticalSpace,
                    _PreviewRow(
                      icon: HugeIcons.strokeRoundedClock02,
                      label: l10n.endTime,
                      value: AppDateFormatter.formatPumpingDateTime(
                        newEnd,
                        context,
                      ),
                    ),
                  ],
                ),
              ),
              16.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: l10n.cancel,
                      isOutline: true,
                      onPressed: state.isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: AppButton(
                      text: l10n.shiftSchedule,
                      isLoading: state.isLoading,
                      onPressed: state.isLoading
                          ? null
                          : () => _submit(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HoursStepper extends StatelessWidget {
  const _HoursStepper({
    required this.hours,
    required this.onChanged,
    required this.minHours,
    required this.maxHours,
  });

  final int hours;
  final ValueChanged<int> onChanged;
  final int minHours;
  final int maxHours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: hours > minHours ? () => onChanged(hours - 1) : null,
            icon: const AppIconWidget(
              icon: HugeIcons.strokeRoundedRemove01,
              size: 20,
              applyPadding: false,
            ),
          ),
          Text(
            '$hours ${l10n.hourAbbreviation}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: hours < maxHours ? () => onChanged(hours + 1) : null,
            icon: const AppIconWidget(
              icon: HugeIcons.strokeRoundedAdd01,
              size: 20,
              applyPadding: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        AppIconWidget(icon: icon, size: 16, applyPadding: false),
        8.horizontalSpace,
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

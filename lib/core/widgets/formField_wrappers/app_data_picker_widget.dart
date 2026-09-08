import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/extensions/datetime_extensions.dart';
import 'package:qatrah/core/utils/formatting_service.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';

class AppDatePickerField extends StatefulWidget {
  const AppDatePickerField({
    required this.hintText,
    required this.value,
    required this.onChanged,
    super.key,
    this.validator,
    this.allowPastDates = false,
    this.showTimePicker = true,
  });
  final String hintText;
  final DateTime? value;
  final void Function(DateTime?) onChanged;

  // Validator
  final String? Function(String?)? validator;

  // Whether to allow past dates (default: false for schedule creation)
  final bool allowPastDates;

  // Whether to show time picker along with date picker (default: true)
  final bool showTimePicker;

  @override
  State<AppDatePickerField> createState() => _AppDatePickerFieldState();
}

class _AppDatePickerFieldState extends State<AppDatePickerField> {
  // 2. Define controller here
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller with initial value
    _controller = TextEditingController(text: _getFormattedDate(widget.value));
  }

  @override
  void didUpdateWidget(covariant AppDatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update text inside controller if value changes from outside
    // Wrap in addPostFrameCallback to prevent markNeedsBuild() during build
    if (widget.value != oldWidget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.text = _getFormattedDate(widget.value);
        }
      });
    }
  }

  @override
  void dispose() {
    // 4. Most important line: clean up memory!
    _controller.dispose();
    super.dispose();
  }

  String _getFormattedDate(DateTime? date) {
    if (date == null) return '';
    if (widget.showTimePicker) {
      return '${FormattingService.formatDayDate(date)}، ${FormattingService.formatTime(date)}';
    }
    return FormattingService.formatDayDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppTextField(
      readOnly: true,
      hintText: widget.hintText,
      controller: _controller,
      // Pass the safe controller
      validator: widget.validator,
      // Enable the validator
      prefixIcon: const AppIconWidget(
        icon: HugeIcons.strokeRoundedCalendar03,
      ),
      onTap: () async {
        final now = DateTime.now();
        final l10n = context.l10n;

        // -----------------------------
        // 1) Select date
        // -----------------------------
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: widget.value ?? now,
          firstDate: widget.allowPastDates ? DateTime(2000) : now,
          lastDate: DateTime(2100),
          // Link date picker colors with app theme
          builder: (context, child) {
            return Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: theme.colorScheme.primary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate == null) return;

        // Validate no past dates
        if (!widget.allowPastDates && pickedDate.isBefore(now.startOfDay)) {
          if (!context.mounted) return;
          getIt<ToastService>().showError(l10n.errorNoPastDates);
          return;
        }

        // -----------------------------
        // 2) Select time (optional based on showTimePicker)
        // -----------------------------
        DateTime combined;
        if (widget.showTimePicker) {
          if (!context.mounted) {
            return; // Protect context in async handling
          }
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(widget.value ?? now),
            builder: (context, child) {
              return Theme(
                data: theme.copyWith(
                  colorScheme: theme.colorScheme.copyWith(
                    primary: theme.colorScheme.primary,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (pickedTime == null) return;

          // Combine date + time
          combined = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        } else {
          // Use date only (time set to 00:00)
          combined = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
          );
        }

        // Final validation: no past dates
        if (!widget.allowPastDates && combined.isBefore(now)) {
          if (!context.mounted) return;
          getIt<ToastService>().showError(l10n.errorNoPastDates);
          return;
        }

        widget.onChanged(combined);
      },
    );
  }
}

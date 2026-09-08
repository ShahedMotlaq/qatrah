import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';

class AddScheduleDialogActionsWidget extends StatelessWidget {
  const AddScheduleDialogActionsWidget({
    required this.isLoading,
    required this.onSave,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: l10n.cancel,
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            isOutline: true,
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: AppButton(
            text: l10n.save,
            onPressed: isLoading ? null : onSave,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}

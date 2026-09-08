import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';
import 'package:qatrah/core/widgets/appdialog/dynamic_form_dialog.dart';
import 'package:qatrah/features/water_feedback/presentation/widgets/feedback_item_option_widget.dart';

class WaterFeedbackDialog extends StatefulWidget {
  const WaterFeedbackDialog({required this.onSelected, super.key});

  final Function(String) onSelected;

  @override
  State<WaterFeedbackDialog> createState() => _WaterFeedbackDialogState();
}

class _WaterFeedbackDialogState extends State<WaterFeedbackDialog> {
  String? _tempSelectedType;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return DynamicFormDialog(
      title: l10n.waterFeedbackTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FeedbackItemOptionWidget(
            isSelected: _tempSelectedType == 'WATER_RECEIVED',
            onTap: () => setState(() => _tempSelectedType = 'WATER_RECEIVED'),
            label: l10n.waterReceived,
            icon: HugeIcons.strokeRoundedCheckmarkSquare01,
            color: Colors.green,
          ),
          10.verticalSpace,
          FeedbackItemOptionWidget(
            isSelected: _tempSelectedType == 'LOW_WATER_LEVEL',
            onTap: () => setState(() => _tempSelectedType = 'LOW_WATER_LEVEL'),
            label: l10n.lowWaterLevel,
            icon: HugeIcons.strokeRoundedInformationSquare,
            color: Colors.orange,
          ),
          10.verticalSpace,
          FeedbackItemOptionWidget(
            isSelected: _tempSelectedType == 'WATER_NOT_RECEIVED',
            onTap: () =>
                setState(() => _tempSelectedType = 'WATER_NOT_RECEIVED'),
            label: l10n.waterNotReceived,
            icon: HugeIcons.strokeRoundedCancelSquare,
            color: Colors.red,
          ),
        ],
      ),
      confirmBtnText: l10n.submit,
      cancelBtnText: l10n.cancel,
      onConfirm: _tempSelectedType != null
          ? () {
              widget.onSelected(_tempSelectedType!);
              context.pop();
            }
          : null,
    );
  }
}

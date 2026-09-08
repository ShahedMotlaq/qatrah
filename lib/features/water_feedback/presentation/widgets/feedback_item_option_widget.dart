import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';

class FeedbackItemOptionWidget extends StatelessWidget {
  const FeedbackItemOptionWidget({
    required this.isSelected,
    required this.onTap,
    required this.label,
    required this.icon,
    required this.color,
    super.key,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final String label;
  final List<List> icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: 0.5),
          width: isSelected ? 1 : .5,
        ),
        color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
      ),
      child: ListTile(
        onTap: onTap,
        leading: AppIconWidget(
          icon: icon,
          color: color,
          applyPadding: false,
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : null,
          ),
        ),
        // Radio icon to enhance visual concept
        trailing: Visibility(
          visible: isSelected,
          child: AppIconWidget(
            applyPadding: false,
            icon: HugeIcons.strokeRoundedTick01,
            color: color,
          ),
        ),
      ),
    );
  }
}

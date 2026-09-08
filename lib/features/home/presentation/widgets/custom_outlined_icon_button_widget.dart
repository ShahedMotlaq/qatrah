import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';

class CustomOutlinedIconButtonWidget extends StatelessWidget {
  const CustomOutlinedIconButtonWidget({
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final List<List> icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton.outlined(
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      icon: AppIconWidget(
        icon: icon,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: onPressed,
    );
  }
}

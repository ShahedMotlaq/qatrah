import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';

class WaterDropAvatarWidget extends StatelessWidget {
  const WaterDropAvatarWidget({
    super.key,
    this.radius = 60,
    this.showBorder = false,
  });

  final double radius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.secondary,
                width: 4.sp,
              ),
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.secondary.withValues(alpha: .25),
        child: AppIconWidget(
          icon: HugeIcons.strokeRoundedDroplet,
          color: theme.colorScheme.primary,
          size: radius * .8,
        ),
      ),
    );
  }
}

// lib/features/navbar/presentation/widgets/custom_nav_item_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_bloc.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_event.dart';

class CustomNavItemWidget extends StatelessWidget {
  const CustomNavItemWidget({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    super.key,
    this.badgeCount,
  });

  final List<List> icon;
  final String label;
  final int index;
  final int currentIndex;

  /// Optional badge count for notification icon
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = index == currentIndex;

    return Expanded(
      child: InkWell(
        onTap: () =>
            context.read<NavbarBloc>().add(ChangeBottomNavTabEvent(index)),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4.h,
              width: isSelected ? 60.w : 0,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            2.verticalSpace,
            // Badge wrapper for notification icon
            Badge.count(
              count: badgeCount != null && badgeCount! > 99
                  ? 99
                  : (badgeCount ?? 0),
              isLabelVisible: badgeCount != null && badgeCount! > 0,
              backgroundColor: theme.colorScheme.error,
              child: AppIconWidget(
                icon: icon,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onPrimary.withValues(alpha: .4),
                size: 24,
              ),
            ),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12.sp,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onPrimary.withValues(alpha: 0.4),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

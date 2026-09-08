import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatCardWidget extends StatelessWidget {
  const StatCardWidget({
    required this.title,
    required this.count,
    required this.color,
    super.key,
  });

  final String title;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          4.verticalSpace,
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 9.sp,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

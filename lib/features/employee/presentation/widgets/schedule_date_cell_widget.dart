import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/utils/app_date_formatter.dart';

class ScheduleDateCellWidget extends StatelessWidget {
  const ScheduleDateCellWidget({
    required this.dateTime,
    super.key,
  });

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppDateFormatter.formatShortDate(dateTime, context),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          AppDateFormatter.formatTimeOnly(dateTime, context),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

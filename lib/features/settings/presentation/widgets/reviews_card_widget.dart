import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';

class ReviewsCardWidget extends StatelessWidget {
  const ReviewsCardWidget({
    required this.title,
    required this.onOpenReviews,
    super.key,
  });

  final String title;
  final VoidCallback onOpenReviews;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onOpenReviews,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: .5),
            ),
          ),
          child: Row(
            children: [
              const AppIconWidget(icon: HugeIcons.strokeRoundedStarAward01),
              16.horizontalSpace,
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

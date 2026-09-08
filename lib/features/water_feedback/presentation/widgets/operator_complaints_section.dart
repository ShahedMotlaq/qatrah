// lib/features/water_feedback/presentation/widgets/operator_complaints_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/features/complaints/domain/entities/complaints_entity.dart';

/// Widget that displays pending complaints for the neighborhood
/// being pumped. Only visible to operators with access to the area.
class OperatorComplaintsSection extends StatelessWidget {
  const OperatorComplaintsSection({
    required this.complaints,
    super.key,
  });
  final List<ComplaintEntity> complaints;

  @override
  Widget build(BuildContext context) {
    if (complaints.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
          _buildComplaintsList(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          AppIconWidget(
            icon: HugeIcons.strokeRoundedAlertSquare,
            color: Theme.of(context).colorScheme.error,
            size: 20.sp,
          ),
          8.horizontalSpace,
          Text(
            'الشكاوى المعلقة في الحي (${complaints.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      itemCount: complaints.length,
      separatorBuilder: (context, index) => Divider(height: 16.h),
      itemBuilder: (context, index) {
        final complaint = complaints[index];
        return _buildComplaintItem(context, complaint);
      },
    );
  }

  Widget _buildComplaintItem(
    BuildContext context,
    ComplaintEntity complaint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
            8.horizontalSpace,
            Expanded(
              child: Text(
                complaint.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (complaint.description.isNotEmpty &&
            complaint.description.trim().isNotEmpty) ...[
          6.verticalSpace,
          Padding(
            padding: EdgeInsetsDirectional.only(start: 12.w),
            child: Text(
              complaint.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          AppIconWidget(
            icon: HugeIcons.strokeRoundedCheckmarkCircle01,
            color: Theme.of(context).colorScheme.primary,
            size: 24.sp,
          ),
          12.horizontalSpace,
          Text(
            'لا توجد شكاوى معلقة في هذا الحي',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

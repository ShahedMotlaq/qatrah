import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart'; // Need intl package for date formatting
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/features/water_feedback/domain/entities/water_feedback_entity.dart';

class FeedbackHistoryItemWidget extends StatelessWidget {
  const FeedbackHistoryItemWidget({required this.item, super.key});

  final WaterFeedbackEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    Color statusColor;
    List<List> statusIcon;
    String statusText;

    switch (item.feedbackType) {
      case 'WATER_RECEIVED':
        statusColor = Colors.green;
        statusIcon = HugeIcons.strokeRoundedCheckmarkSquare01;
        statusText = l10n.waterArrived;
      case 'LOW_WATER_LEVEL':
        statusColor = Colors.orange;
        statusIcon = HugeIcons.strokeRoundedInformationSquare;
        statusText = l10n.lowPressure;
      case 'WATER_NOT_RECEIVED':
      default:
        statusColor = Colors.red;
        statusIcon = HugeIcons.strokeRoundedCancelSquare;
        statusText = l10n.didNotArrive;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: AppIconWidget(
              icon: statusIcon,
              color: statusColor,
              size: 24,
            ),
          ),
          12.horizontalSpace,
          // Feedback details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.schedulePath, // Spatial path of the schedule
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                4.verticalSpace,
                Text(
                  statusText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
                4.verticalSpace,
                Text(
                  DateFormat('yyyy/MM/dd - hh:mm a').format(item.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (item.adminResponse != null &&
                    item.adminResponse!.isNotEmpty) ...[
                  8.verticalSpace,
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppIconWidget(
                          icon: HugeIcons.strokeRoundedBuilding03,
                          color: Colors.green.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.adminResponse!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

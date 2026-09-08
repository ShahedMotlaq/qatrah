import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/features/notifications/domain/entities/notification_type.dart';

class NotificationItemWidget extends StatelessWidget {
  const NotificationItemWidget({
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    super.key,
    this.isUnread = false,
  });

  final NotificationType type;
  final String title;
  final String body;
  final String time;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color iconColor;
    Color bgColor;
    List<List> iconData;

    switch (type) {
      case NotificationType.start:
        iconColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.15);
        iconData = HugeIcons.strokeRoundedPlay;
      case NotificationType.stop:
        iconColor = Colors.indigo;
        bgColor = Colors.indigo.withValues(alpha: 0.15);
        iconData = HugeIcons.strokeRoundedStop;
      case NotificationType.pause:
        iconColor = Colors.amber;
        bgColor = Colors.amber.withValues(alpha: 0.15);
        iconData = HugeIcons.strokeRoundedPause;
      case NotificationType.resume:
        iconColor = Colors.teal;
        bgColor = Colors.teal.withValues(alpha: 0.15);
        iconData = HugeIcons.strokeRoundedPlay;
      case NotificationType.edit:
        iconColor = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.15);
        iconData = HugeIcons.strokeRoundedCalendarAdd02;
      case NotificationType.cancel:
        iconColor = theme.colorScheme.secondary;
        bgColor = theme.colorScheme.secondary.withValues(alpha: 0.15);
        iconData = HugeIcons.strokeRoundedRemoveCircle;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: bgColor,
            child: AppIconWidget(icon: iconData, color: iconColor, size: 28),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                4.verticalSpace,
                Text(
                  body,
                  maxLines: 2,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                8.verticalSpace,
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    4.horizontalSpace,
                    Text(
                      time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Unread notification dot (if notification is new)
          if (isUnread) ...[
            8.horizontalSpace,
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1B4D3E), // Green color
                shape: BoxShape.circle,
              ),
            ),
          ] else ...[
            16.horizontalSpace,
          ],
        ],
      ),
    );
  }
}

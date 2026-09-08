// lib/features/notifications/data/models/notification_model.dart
//
// Serialization layer for [NotificationEntity]. The domain entity stays pure
// Dart; JSON mapping (incl. API-type translation) lives here as an extension.

import 'package:qatrah/features/notifications/domain/entities/notification_type.dart';
import 'package:qatrah/features/notifications/domain/entities/notifications_entity.dart';

extension NotificationModelMapper on NotificationEntity {
  static NotificationEntity fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: _mapApiTypeToEnum(json['type'] as String?),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseCreatedAt(json['createdAt']),
      pumpingScheduleId: (json['pumpingScheduleId'] as num?)?.toInt(),
      // Location fields — nullable, gracefully handle missing data
      regionName: json['regionName'] as String?,
      unitName: json['unitName'] as String?,
      neighborhoodName: json['neighborhoodName'] as String?,
      zoneName: json['zoneName'] as String?,
    );
  }
}

DateTime _parseCreatedAt(dynamic value) {
  final parsed = value is String ? DateTime.tryParse(value) : null;
  return (parsed ?? DateTime.now()).toLocal();
}

NotificationType _mapApiTypeToEnum(String? apiType) {
  switch (apiType) {
    case 'PUMPING_STARTED':
      return NotificationType.start;
    case 'PUMPING_ENDED':
      return NotificationType.stop;
    case 'PUMPING_PAUSED':
      return NotificationType.pause;
    case 'PUMPING_RESUMED':
      return NotificationType.resume;
    case 'SCHEDULE_UPDATED':
      return NotificationType.edit;
    case 'SCHEDULE_CANCELLED':
      return NotificationType.cancel;
    default:
      return NotificationType.start;
  }
}

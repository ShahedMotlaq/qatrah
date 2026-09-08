import 'package:equatable/equatable.dart';
import 'package:qatrah/features/notifications/domain/entities/notification_type.dart';

class NotificationEntity extends Equatable {
  // Zone

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.pumpingScheduleId,
    this.regionName,
    this.unitName,
    this.neighborhoodName,
    this.zoneName,
  });

  final int id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final int? pumpingScheduleId;

  // Location hierarchy fields for detailed notification display
  final String? regionName; // Region
  final String? unitName; // Unit / Center
  final String? neighborhoodName; // Neighborhood
  final String? zoneName;

  NotificationEntity copyWith({
    int? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    int? pumpingScheduleId,
    String? regionName,
    String? unitName,
    String? neighborhoodName,
    String? zoneName,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      pumpingScheduleId: pumpingScheduleId ?? this.pumpingScheduleId,
      regionName: regionName ?? this.regionName,
      unitName: unitName ?? this.unitName,
      neighborhoodName: neighborhoodName ?? this.neighborhoodName,
      zoneName: zoneName ?? this.zoneName,
    );
  }

  /// Formats the location hierarchy into a single display string.
  /// Example: 'Region: Damascus - Unit: Center 1 - Neighborhood: Mazzeh'
  /// If all fields are null, returns an empty string.
  String formatLocationDetails() {
    final parts = <String>[];

    if (regionName != null && regionName!.isNotEmpty) {
      parts.add('المنطقة: $regionName');
    }
    if (unitName != null && unitName!.isNotEmpty) {
      parts.add('المركز: $unitName');
    }
    if (neighborhoodName != null && neighborhoodName!.isNotEmpty) {
      parts.add('الحي: $neighborhoodName');
    }
    if (zoneName != null && zoneName!.isNotEmpty) {
      parts.add('المربع: $zoneName');
    }

    return parts.join(' - ');
  }

  @override
  List<Object?> get props => [
    id,
    title,
    message,
    type,
    isRead,
    createdAt,
    pumpingScheduleId,
    regionName,
    unitName,
    neighborhoodName,
    zoneName,
  ];
}

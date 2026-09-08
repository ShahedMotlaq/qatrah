import 'package:equatable/equatable.dart';

enum ComplaintCategory {
  NO_WATER,
  WATER_QUALITY,
  LOW_PRESSURE,
  SCHEDULE_ISSUE,
  OTHER,
}

class ComplaintEntity extends Equatable {
  const ComplaintEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.category,
    required this.createdAt,
    this.userId,
    this.userName,
    this.userPhone,
    this.regionId,
    this.regionName,
    this.unitId,
    this.unitName,
    this.neighborhoodId,
    this.neighborhoodName,
    this.zoneId,
    this.zoneName,
    this.adminResponse,
    this.handledByAdminId,
    this.handledByAdminName,
    this.handledAt,
    this.updatedAt,
  });

  factory ComplaintEntity.fromJson(Map<String, dynamic> json) {
    return ComplaintEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt(),
      userName: json['userName'] as String?,
      userPhone: json['userPhone'] as String?,
      regionId: (json['regionId'] as num?)?.toInt(),
      regionName: json['regionName'] as String?,
      unitId: (json['unitId'] as num?)?.toInt(),
      unitName: json['unitName'] as String?,
      neighborhoodId: (json['neighborhoodId'] as num?)?.toInt(),
      neighborhoodName: json['neighborhoodName'] as String?,
      zoneId: (json['zoneId'] as num?)?.toInt(),
      zoneName: json['zoneName'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      category: json['category'] as String? ?? 'OTHER',
      adminResponse: json['adminResponse'] as String?,
      handledByAdminId: (json['handledByAdminId'] as num?)?.toInt(),
      handledByAdminName: json['handledByAdminName'] as String?,
      handledAt: _parseDate(json['handledAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
  final int id;
  final int? userId;
  final String? userName;
  final String? userPhone;
  final int? regionId;
  final String? regionName;
  final int? unitId;
  final String? unitName;
  final int? neighborhoodId;
  final String? neighborhoodName;
  final int? zoneId;
  final String? zoneName;
  final String title;
  final String description;
  final String status; // PENDING, IN_PROGRESS, RESOLVED, REJECTED
  final String category;
  final String? adminResponse;
  final int? handledByAdminId;
  final String? handledByAdminName;
  final DateTime? handledAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDate(dynamic value) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    return parsed?.toLocal();
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    userPhone,
    regionId,
    regionName,
    unitId,
    unitName,
    neighborhoodId,
    neighborhoodName,
    zoneId,
    zoneName,
    title,
    description,
    status,
    category,
    adminResponse,
    handledByAdminId,
    handledByAdminName,
    handledAt,
    createdAt,
    updatedAt,
  ];
}

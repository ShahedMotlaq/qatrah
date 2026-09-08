// lib/features/profile/data/models/address_model.dart
//
// Serialization layer for [AddressEntity]. The domain entity stays pure Dart;
// JSON mapping lives here as an extension.

import 'package:qatrah/features/profile/domain/entities/address_entity.dart';

extension AddressModelMapper on AddressEntity {
  static AddressEntity fromJson(Map<String, dynamic> json) {
    final region = json['region'];
    final unit = json['unit'];
    final neighborhood = json['neighborhood'];
    final zone = json['zone'];

    return AddressEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      regionId: (json['regionId'] as num?)?.toInt() ?? _nestedId(region),
      regionName: json['regionName']?.toString() ?? _nestedName(region),
      unitId: (json['unitId'] as num?)?.toInt() ?? _nestedId(unit),
      unitName: json['unitName']?.toString() ?? _nestedName(unit),
      neighborhoodId:
          (json['neighborhoodId'] as num?)?.toInt() ?? _nestedId(neighborhood),
      neighborhoodName:
          json['neighborhoodName']?.toString() ?? _nestedName(neighborhood),
      zoneId: (json['zoneId'] as num?)?.toInt() ?? _nestedId(zone),
      zoneName: json['zoneName']?.toString() ?? _nestedName(zone),
      createdAt: json['createdAt']?.toString() ?? '',
      isDefault:
          json['isDefault'] as bool? ?? json['is_default'] as bool? ?? false,
    );
  }
}

int _nestedId(dynamic value) {
  if (value is Map) return (value['id'] as num?)?.toInt() ?? 0;
  return 0;
}

String _nestedName(dynamic value) {
  if (value is Map) return value['name']?.toString() ?? '';
  return '';
}

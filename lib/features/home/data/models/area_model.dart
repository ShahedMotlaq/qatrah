// lib/features/home/data/models/area_model.dart
//
// Serialization layer for [AreaEntity]. The domain entity stays pure Dart;
// JSON mapping lives here as an extension.

import 'package:qatrah/features/home/domain/entities/area_entity.dart';

extension AreaModelMapper on AreaEntity {
  static AreaEntity fromHierarchyJson(Map<String, dynamic> json) {
    return AreaEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      regionName: json['regionName'] as String? ?? '',
      unitName: json['unitName'] as String? ?? '',
      neighborhoodName: json['neighborhoodName'] as String? ?? '',
      zoneName: json['zoneName'] as String? ?? '',
    );
  }

  static AreaEntity fromJson(Map<String, dynamic> json) {
    return AreaEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      regionName: json['regionName'] as String,
      unitName: json['unitName'] as String,
      neighborhoodName: json['neighborhoodName'] as String,
      zoneName: json['zoneName'] as String,
      isWatched: json['isWatched'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'regionName': regionName,
      'unitName': unitName,
      'neighborhoodName': neighborhoodName,
      'zoneName': zoneName,
      'isWatched': isWatched,
    };
  }
}

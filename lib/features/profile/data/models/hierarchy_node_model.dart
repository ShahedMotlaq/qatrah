// lib/features/profile/data/models/hierarchy_node_model.dart
//
// Serialization layer for [HierarchyNodeEntity]. The domain entity stays pure
// Dart; JSON mapping lives here as an extension.

import 'package:qatrah/features/profile/domain/entities/hierarchy_node_entity.dart';

extension HierarchyNodeModelMapper on HierarchyNodeEntity {
  /// Reads one node of `GET /hierarchy/tree`, recursing into `children`.
  ///
  /// A node whose `type` is unknown is skipped along with its subtree — see
  /// [fromJsonList].
  static HierarchyNodeEntity? fromJson(Map<String, dynamic> json) {
    final level = HierarchyLevel.fromType(json['type']?.toString());
    if (level == null) return null;

    return HierarchyNodeEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      level: level,
      active: json['active'] as bool? ?? true,
      regionId: (json['regionId'] as num?)?.toInt(),
      unitId: (json['unitId'] as num?)?.toInt(),
      neighborhoodId: (json['neighborhoodId'] as num?)?.toInt(),
      regionName: json['regionName']?.toString(),
      unitName: json['unitName']?.toString(),
      neighborhoodName: json['neighborhoodName']?.toString(),
      children: fromJsonList(json['children']),
    );
  }

  static List<HierarchyNodeEntity> fromJsonList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .whereType<HierarchyNodeEntity>()
        .toList();
  }
}

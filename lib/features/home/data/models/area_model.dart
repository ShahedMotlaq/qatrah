// lib/features/home/data/models/area_model.dart
//
// Serialization layer for [AreaEntity]. The domain entity stays pure Dart;
// JSON mapping lives here as an extension.

import 'package:qatrah/features/home/domain/entities/area_entity.dart';
import 'package:qatrah/features/profile/domain/entities/hierarchy_node_entity.dart';

extension AreaModelMapper on AreaEntity {
  /// One node of the cached location tree as an area. A node names itself in
  /// [AreaEntity.name] and its ancestors in the rest; [AreaEntity.zoneName] is
  /// only filled for an actual zone, which is the level pumping happens at.
  static AreaEntity fromHierarchyNode(HierarchyNodeEntity node) {
    return AreaEntity(
      id: node.id,
      name: node.name,
      regionName: node.regionName ?? '',
      unitName: node.unitName ?? '',
      neighborhoodName: node.neighborhoodName ?? '',
      zoneName: node.level == HierarchyLevel.zone ? node.name : '',
    );
  }
}

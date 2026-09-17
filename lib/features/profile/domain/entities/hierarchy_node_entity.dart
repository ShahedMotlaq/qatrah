import 'package:equatable/equatable.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

/// The four levels of the location tree, outermost first:
/// Region (المنطقة) → Unit (الناحية) → Neighborhood (الوحدة الإدارية) →
/// Zone (الحي). Pumping happens per zone.
enum HierarchyLevel {
  region,
  unit,
  neighborhood,
  zone;

  static HierarchyLevel? fromType(String? type) {
    return switch (type?.trim().toLowerCase()) {
      'region' => HierarchyLevel.region,
      'unit' => HierarchyLevel.unit,
      'neighborhood' => HierarchyLevel.neighborhood,
      'zone' => HierarchyLevel.zone,
      _ => null,
    };
  }
}

/// One node of `GET /hierarchy/tree`.
///
/// Each node carries its ancestors' ids, so a saved zone can be resolved back
/// up the tree without walking it.
class HierarchyNodeEntity extends Equatable {
  const HierarchyNodeEntity({
    required this.id,
    required this.name,
    required this.level,
    this.active = true,
    this.regionId,
    this.unitId,
    this.neighborhoodId,
    this.regionName,
    this.unitName,
    this.neighborhoodName,
    this.children = const [],
  });

  final int id;
  final String name;
  final HierarchyLevel level;
  final bool active;

  final int? regionId;
  final int? unitId;
  final int? neighborhoodId;

  final String? regionName;
  final String? unitName;
  final String? neighborhoodName;

  final List<HierarchyNodeEntity> children;

  /// The id of this node's parent, or null for a region.
  int? get parentId => switch (level) {
    HierarchyLevel.region => null,
    HierarchyLevel.unit => regionId,
    HierarchyLevel.neighborhood => unitId,
    HierarchyLevel.zone => neighborhoodId,
  };

  /// The shape the existing dropdowns and breadcrumb selector consume.
  LocationLookupEntity get asLookup =>
      LocationLookupEntity(id: id, name: name);

  /// This node and its whole subtree, depth-first — the same order and
  /// content `GET /hierarchy/flat` serves, without a second request.
  List<HierarchyNodeEntity> flatten() => [
    this,
    for (final child in children) ...child.flatten(),
  ];

  @override
  String toString() => name;

  @override
  List<Object?> get props => [id, level];
}

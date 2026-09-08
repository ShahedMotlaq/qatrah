// lib/features/auth/domain/entities/assigned_region_entity.dart

class AssignedRegionEntity {
  const AssignedRegionEntity({
    required this.regionId,
    required this.regionName,
    this.unitIds = const [],
    this.unitNames = const [],
  });

  final int regionId;
  final String regionName;
  final List<int> unitIds;
  final List<String> unitNames;

  @override
  String toString() => '$regionName (ID: $regionId)';
}

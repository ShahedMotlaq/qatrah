// lib/features/home/domain/entities/area_entity.dart

class AreaEntity {
  const AreaEntity({
    required this.id,
    required this.name,
    required this.regionName,
    required this.unitName,
    required this.neighborhoodName,
    required this.zoneName,
    this.isWatched = false,
  });

  final int id;
  final String name;
  final String regionName;
  final String unitName;
  final String neighborhoodName;
  final String zoneName;
  final bool isWatched;

  AreaEntity copyWith({
    int? id,
    String? name,
    String? regionName,
    String? unitName,
    String? neighborhoodName,
    String? zoneName,
    bool? isWatched,
  }) {
    return AreaEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      regionName: regionName ?? this.regionName,
      unitName: unitName ?? this.unitName,
      neighborhoodName: neighborhoodName ?? this.neighborhoodName,
      zoneName: zoneName ?? this.zoneName,
      isWatched: isWatched ?? this.isWatched,
    );
  }
}

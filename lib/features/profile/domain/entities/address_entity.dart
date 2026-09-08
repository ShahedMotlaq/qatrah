class AddressEntity {
  const AddressEntity({
    required this.id,
    required this.title,
    required this.regionId,
    required this.regionName,
    required this.unitId,
    required this.unitName,
    required this.neighborhoodId,
    required this.neighborhoodName,
    required this.zoneId,
    required this.zoneName,
    required this.createdAt,
    this.isDefault = false,
  });

  final int id;
  final String title;
  final int regionId;
  final String regionName;
  final int unitId;
  final String unitName;
  final int neighborhoodId;
  final String neighborhoodName;
  final int zoneId;
  final String zoneName;
  final String createdAt;
  final bool isDefault;

  AddressEntity copyWith({
    int? id,
    String? title,
    int? regionId,
    String? regionName,
    int? unitId,
    String? unitName,
    int? neighborhoodId,
    String? neighborhoodName,
    int? zoneId,
    String? zoneName,
    String? createdAt,
    bool? isDefault,
  }) {
    return AddressEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      regionId: regionId ?? this.regionId,
      regionName: regionName ?? this.regionName,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
      neighborhoodName: neighborhoodName ?? this.neighborhoodName,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get homeLocationName {
    if (zoneName.isNotEmpty) return zoneName;
    if (neighborhoodName.isNotEmpty) return neighborhoodName;
    if (unitName.isNotEmpty) return unitName;
    return regionName;
  }
}

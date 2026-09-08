import 'package:json_annotation/json_annotation.dart';

part 'unit_dto_entity.g.dart';

@JsonSerializable()
class UnitDtoEntity {
  const UnitDtoEntity({
    required this.id,
    required this.regionId,
    required this.regionName,
    required this.name,
    required this.description,
    required this.active,
    required this.creaedAt,
    required this.updatedAt,
  });

  factory UnitDtoEntity.fromJson(Map<String, dynamic> json) =>
      _$UnitDtoEntityFromJson(json);
  final int id;
  final int regionId;
  final String regionName;
  final String name;
  final String description;
  final bool active;
  final DateTime creaedAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$UnitDtoEntityToJson(this);
}

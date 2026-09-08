import 'package:json_annotation/json_annotation.dart';

part 'region_dto_entity.g.dart';

@JsonSerializable()
class RegionDtoEntity {
  const RegionDtoEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
  });

  factory RegionDtoEntity.fromJson(Map<String, dynamic> json) =>
      _$RegionDtoEntityFromJson(json);
  final int id;
  final String name;
  final String description;
  final bool active;

  Map<String, dynamic> toJson() => _$RegionDtoEntityToJson(this);
}

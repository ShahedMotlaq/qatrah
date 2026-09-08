// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_dto_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitDtoEntity _$UnitDtoEntityFromJson(Map<String, dynamic> json) =>
    UnitDtoEntity(
      id: (json['id'] as num).toInt(),
      regionId: (json['regionId'] as num).toInt(),
      regionName: json['regionName'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      active: json['active'] as bool,
      creaedAt: DateTime.parse(json['creaedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UnitDtoEntityToJson(UnitDtoEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'regionId': instance.regionId,
      'regionName': instance.regionName,
      'name': instance.name,
      'description': instance.description,
      'active': instance.active,
      'creaedAt': instance.creaedAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

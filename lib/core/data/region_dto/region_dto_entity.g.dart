// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region_dto_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegionDtoEntity _$RegionDtoEntityFromJson(Map<String, dynamic> json) =>
    RegionDtoEntity(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      active: json['active'] as bool,
    );

Map<String, dynamic> _$RegionDtoEntityToJson(RegionDtoEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'active': instance.active,
    };

// lib/features/auth/data/models/user_model.dart
//
// Serialization layer for [UserEntity]. The domain entity stays pure Dart;
// JSON mapping lives here as an extension (the feature blueprint).

import 'package:qatrah/features/auth/domain/entities/assigned_region_entity.dart';
import 'package:qatrah/features/auth/domain/entities/user_entity.dart';

extension UserModelMapper on UserEntity {
  static UserEntity fromJson(Map<String, dynamic> json) {
    // ✅ Parse assignedUnits (units with unit data)
    final assignedUnitsRaw = json['assignedUnits'] as List<dynamic>?;
    final assignedUnitIds =
        assignedUnitsRaw
            ?.map((e) {
              if (e is num) return e.toInt();
              if (e is Map<String, dynamic>) {
                return (e['id'] as num?)?.toInt();
              }
              if (e is Map) {
                return (e['id'] as num?)?.toInt();
              }
              return int.tryParse(e.toString());
            })
            .whereType<int>()
            .toList() ??
        const <int>[];
    final assignedUnitNames =
        assignedUnitsRaw
            ?.map((e) {
              if (e is Map<String, dynamic>) {
                return e['name']?.toString();
              }
              if (e is Map) {
                return e['name']?.toString();
              }
              return null;
            })
            .whereType<String>()
            .where((name) => name.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    // ✅ Parse assignedRegions (extract unique regions from assignedUnits)
    final assignedRegionsById = <int, AssignedRegionEntity>{};
    final assignedRegionIdsList = <int>[];
    final assignedRegionNamesList = <String>[];

    assignedUnitsRaw?.forEach((unitData) {
      if (unitData is Map<String, dynamic>) {
        final regionId = (unitData['regionId'] as num?)?.toInt();
        final regionName = unitData['regionName'] as String?;
        final unitId = (unitData['id'] as num?)?.toInt();
        final unitName = unitData['name'] as String?;

        if (regionId != null &&
            regionId > 0 &&
            regionName != null &&
            regionName.isNotEmpty) {
          // ✅ Ensure unique regions
          final existing = assignedRegionsById[regionId];
          if (existing == null) {
            assignedRegionIdsList.add(regionId);
            assignedRegionNamesList.add(regionName);
            assignedRegionsById[regionId] = AssignedRegionEntity(
              regionId: regionId,
              regionName: regionName,
              unitIds: unitId == null ? const [] : [unitId],
              unitNames: unitName == null || unitName.isEmpty
                  ? const []
                  : [unitName],
            );
          } else {
            assignedRegionsById[regionId] = AssignedRegionEntity(
              regionId: existing.regionId,
              regionName: existing.regionName,
              unitIds: unitId == null
                  ? existing.unitIds
                  : [...existing.unitIds, unitId],
              unitNames: unitName == null || unitName.isEmpty
                  ? existing.unitNames
                  : [...existing.unitNames, unitName],
            );
          }
        }
      }
    });

    final defaultAddress =
        json['defaultAddressDetails'] ?? json['defaultAddress'];
    final defaultRegion = defaultAddress is Map
        ? defaultAddress['region']
        : null;
    final defaultUnit = defaultAddress is Map ? defaultAddress['unit'] : null;
    final defaultNeighborhood = defaultAddress is Map
        ? defaultAddress['neighborhood']
        : null;
    final defaultZone = defaultAddress is Map ? defaultAddress['zone'] : null;

    return UserEntity(
      token: json['token'] as String? ?? '',
      refreshToken:
          (json['refreshToken'] as String?) ??
          (json['refresh_token'] as String?),
      userId:
          (json['userId'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      role: json['role'] as String? ?? 'CITIZEN',
      active: json['active'] as bool? ?? true,
      profileComplete: json['profileComplete'] as bool? ?? false,
      defaultAddressId:
          (json['defaultAddressId'] as num?)?.toInt() ??
          (defaultAddress is Map
              ? (defaultAddress['id'] as num?)?.toInt()
              : null) ??
          0,
      defaultRegionId:
          (json['defaultRegionId'] as num?)?.toInt() ??
          _nestedId(defaultRegion) ??
          (defaultAddress is Map
              ? (defaultAddress['regionId'] as num?)?.toInt()
              : null) ??
          0,
      defaultRegionName:
          json['defaultRegionName'] as String? ??
          _nestedName(defaultRegion) ??
          (defaultAddress is Map
              ? defaultAddress['regionName']?.toString()
              : null),
      defaultUnitId:
          (json['defaultUnitId'] as num?)?.toInt() ??
          _nestedId(defaultUnit) ??
          (defaultAddress is Map
              ? (defaultAddress['unitId'] as num?)?.toInt()
              : null) ??
          0,
      defaultUnitName:
          json['defaultUnitName'] as String? ??
          _nestedName(defaultUnit) ??
          (defaultAddress is Map
              ? defaultAddress['unitName']?.toString()
              : null),
      defaultNeighborhoodId:
          (json['defaultNeighborhoodId'] as num?)?.toInt() ??
          _nestedId(defaultNeighborhood) ??
          (defaultAddress is Map
              ? (defaultAddress['neighborhoodId'] as num?)?.toInt()
              : null) ??
          0,
      defaultNeighborhoodName:
          json['defaultNeighborhoodName'] as String? ??
          _nestedName(defaultNeighborhood) ??
          (defaultAddress is Map
              ? defaultAddress['neighborhoodName']?.toString()
              : null),
      defaultZoneId:
          (json['defaultZoneId'] as num?)?.toInt() ??
          _nestedId(defaultZone) ??
          (defaultAddress is Map
              ? (defaultAddress['zoneId'] as num?)?.toInt()
              : null) ??
          0,
      defaultZoneName:
          json['defaultZoneName'] as String? ??
          _nestedName(defaultZone) ??
          (defaultAddress is Map
              ? defaultAddress['zoneName']?.toString()
              : null),
      watchedRegionId: (json['watchedRegionId'] as num?)?.toInt() ?? 0,
      watchedRegionName: json['watchedRegionName'] as String?,
      watchedUnitId: (json['watchedUnitId'] as num?)?.toInt() ?? 0,
      watchedUnitName: json['watchedUnitName'] as String?,
      watchedNeighborhoodId:
          (json['watchedNeighborhoodId'] as num?)?.toInt() ?? 0,
      watchedNeighborhoodName: json['watchedNeighborhoodName'] as String?,
      watchedZoneId: (json['watchedZoneId'] as num?)?.toInt() ?? 0,
      watchedZoneName: json['watchedZoneName'] as String?,
      assignedUnits: assignedUnitIds,
      assignedUnitNames: assignedUnitNames,
      assignedRegions: assignedRegionsById.values.toList(),
      assignedRegionIds: assignedRegionIdsList,
      assignedRegionNames: assignedRegionNamesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'userId': userId,
      'username': username,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'active': active,
      'profileComplete': profileComplete,
      'defaultAddressId': defaultAddressId,
      'defaultRegionId': defaultRegionId,
      'defaultRegionName': defaultRegionName,
      'defaultUnitId': defaultUnitId,
      'defaultUnitName': defaultUnitName,
      'defaultNeighborhoodId': defaultNeighborhoodId,
      'defaultNeighborhoodName': defaultNeighborhoodName,
      'defaultZoneId': defaultZoneId,
      'defaultZoneName': defaultZoneName,
      'watchedRegionId': watchedRegionId,
      'watchedRegionName': watchedRegionName,
      'watchedUnitId': watchedUnitId,
      'watchedUnitName': watchedUnitName,
      'watchedNeighborhoodId': watchedNeighborhoodId,
      'watchedNeighborhoodName': watchedNeighborhoodName,
      'watchedZoneId': watchedZoneId,
      'watchedZoneName': watchedZoneName,
      'assignedUnits': assignedUnits,
      'assignedUnitNames': assignedUnitNames,
      'assignedRegionIds': assignedRegionIds,
      'assignedRegionNames': assignedRegionNames,
    };
  }
}

int? _nestedId(dynamic value) {
  if (value is Map) return (value['id'] as num?)?.toInt();
  return null;
}

String? _nestedName(dynamic value) {
  if (value is Map) return value['name']?.toString();
  return null;
}

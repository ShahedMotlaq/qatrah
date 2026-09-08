// lib/features/profile/data/models/location_lookup_model.dart
//
// Serialization layer for [LocationLookupEntity]. The domain entity stays pure
// Dart; JSON mapping lives here as an extension.

import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

extension LocationLookupModelMapper on LocationLookupEntity {
  static LocationLookupEntity fromJson(Map<String, dynamic> json) {
    return LocationLookupEntity(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

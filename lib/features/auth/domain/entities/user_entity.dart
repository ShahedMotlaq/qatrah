// lib/features/auth/domain/entities/user_entity.dart

import 'package:qatrah/features/auth/domain/entities/assigned_region_entity.dart';
import 'package:qatrah/features/auth/domain/entities/user_role.dart';

class UserEntity {
  const UserEntity({
    required this.token,
    required this.userId,
    required this.username,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.profileComplete,
    this.refreshToken,
    this.active = true,
    this.defaultAddressId = 0,
    this.defaultRegionId = 0,
    this.defaultRegionName,
    this.defaultUnitId = 0,
    this.defaultUnitName,
    this.defaultNeighborhoodId = 0,
    this.defaultNeighborhoodName,
    this.defaultZoneId = 0,
    this.defaultZoneName,
    this.watchedRegionId = 0,
    this.watchedRegionName,
    this.watchedUnitId = 0,
    this.watchedUnitName,
    this.watchedNeighborhoodId = 0,
    this.watchedNeighborhoodName,
    this.watchedZoneId = 0,
    this.watchedZoneName,
    this.assignedUnits = const [],
    this.assignedUnitNames = const [],
    this.assignedRegions = const [],
    this.assignedRegionIds = const [],
    this.assignedRegionNames = const [],
  });

  final String token;
  final String? refreshToken;
  final int userId;
  final String username;
  final String fullName;
  final String phoneNumber;
  final String role;
  final bool active;
  final bool profileComplete;

  final int defaultAddressId;
  final int defaultRegionId;
  final String? defaultRegionName;
  final int defaultUnitId;
  final String? defaultUnitName;
  final int defaultNeighborhoodId;
  final String? defaultNeighborhoodName;
  final int defaultZoneId;
  final String? defaultZoneName;

  final int watchedRegionId;
  final String? watchedRegionName;
  final int watchedUnitId;
  final String? watchedUnitName;
  final int watchedNeighborhoodId;
  final String? watchedNeighborhoodName;
  final int watchedZoneId;
  final String? watchedZoneName;

  final List<int> assignedUnits;
  final List<String> assignedUnitNames;
  final List<AssignedRegionEntity> assignedRegions;
  final List<int> assignedRegionIds;
  final List<String> assignedRegionNames;

  bool get isAdmin => role == 'ADMIN';
  bool get isEmployee => role == 'OPERATOR' || role == 'ADMIN';
  bool get isCitizen => role == 'CITIZEN';

  /// Type-safe role getter using UserRole enum
  UserRole get userRole => UserRole.fromString(role);

  // ✅ Fallback getters: use default fields first, fallback to watched fields
  // This handles the case where API returns null for default* but has data in watched*

  /// Effective region ID (default > watched)
  int get effectiveRegionId =>
      defaultRegionId > 0 ? defaultRegionId : watchedRegionId;

  /// Effective region name (default > watched)
  String? get effectiveRegionName => defaultRegionName?.isNotEmpty ?? false
      ? defaultRegionName
      : watchedRegionName;

  /// Effective unit ID (default > watched)
  int get effectiveUnitId => defaultUnitId > 0 ? defaultUnitId : watchedUnitId;

  /// Effective unit name (default > watched)
  String? get effectiveUnitName =>
      defaultUnitName?.isNotEmpty ?? false ? defaultUnitName : watchedUnitName;

  /// Effective neighborhood ID (default > watched)
  int get effectiveNeighborhoodId =>
      defaultNeighborhoodId > 0 ? defaultNeighborhoodId : watchedNeighborhoodId;

  /// Effective neighborhood name (default > watched)
  String? get effectiveNeighborhoodName =>
      defaultNeighborhoodName?.isNotEmpty ?? false
      ? defaultNeighborhoodName
      : watchedNeighborhoodName;

  /// Effective zone ID (default > watched)
  int get effectiveZoneId => defaultZoneId > 0 ? defaultZoneId : watchedZoneId;

  /// Effective zone name (default > watched)
  String? get effectiveZoneName =>
      defaultZoneName?.isNotEmpty ?? false ? defaultZoneName : watchedZoneName;

  /// Check if user has ANY location data (default OR watched)
  bool get hasAnyLocationData =>
      (defaultRegionId > 0 || watchedRegionId > 0) ||
      (defaultUnitId > 0 || watchedUnitId > 0) ||
      (defaultNeighborhoodId > 0 || watchedNeighborhoodId > 0) ||
      (defaultZoneId > 0 || watchedZoneId > 0) ||
      ((defaultRegionName?.isNotEmpty ?? false) ||
          (watchedRegionName?.isNotEmpty ?? false)) ||
      ((defaultUnitName?.isNotEmpty ?? false) ||
          (watchedUnitName?.isNotEmpty ?? false)) ||
      ((defaultNeighborhoodName?.isNotEmpty ?? false) ||
          (watchedNeighborhoodName?.isNotEmpty ?? false)) ||
      ((defaultZoneName?.isNotEmpty ?? false) ||
          (watchedZoneName?.isNotEmpty ?? false));
}

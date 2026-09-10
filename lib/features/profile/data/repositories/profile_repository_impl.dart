import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/features/auth/data/models/user_model.dart';
import 'package:qatrah/features/auth/domain/entities/user_entity.dart';
import 'package:qatrah/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:qatrah/features/profile/domain/usecases/update_profile_usecases.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  ProfileRepositoryImpl(this._apiService, this._secureStorage);

  final ApiService _apiService;
  final SecureStorage _secureStorage;

  @override
  Future<Either<Failure, UserEntity>> getProfile() async {
    try {
      final responseData = await _apiService.get(
        endPoint: ApiEndpoints.currentUser,
      );
      final userJson = _unwrapUser(responseData);
      final mergedJson = await _mergeWithStoredData(userJson);
      return Right(UserModelMapper.fromJson(mergedJson));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure('Error fetching profile data'));
    }
  }

  /// Merges API response with locally-stored data for fields the backend
  /// sometimes returns as null (watched locations, assigned units).
  /// The API wins for most fields; stored data is used only as a fallback
  /// when the API returns null / empty / zero values.
  Future<Map<String, dynamic>> _mergeWithStoredData(
    Map<String, dynamic> apiJson,
  ) async {
    final merged = Map<String, dynamic>.from(apiJson);

    // ── assignedUnits fallback ────────────────────────────────────────────
    final apiAssignedUnits = merged['assignedUnits'];
    final hasAssignedUnits =
        apiAssignedUnits is List && apiAssignedUnits.isNotEmpty;
    if (!hasAssignedUnits) {
      final storedUserData = await _secureStorage.getUserData();
      if (storedUserData != null && storedUserData.isNotEmpty) {
        try {
          final stored = jsonDecode(storedUserData) as Map<String, dynamic>;
          final storedAssignedUnits = stored['assignedUnits'];
          if (storedAssignedUnits is List && storedAssignedUnits.isNotEmpty) {
            // Use the full objects saved at login (includes names, regionIds, etc.)
            merged['assignedUnits'] = storedAssignedUnits;
          }
        } catch (_) {
          // If stored JSON is corrupt, fall through to ID-only reconstruction.
        }
      }
      // If still empty, reconstruct from stored unit IDs as a last resort.
      final apiAssignedUnitsAfterRestore = merged['assignedUnits'];
      final stillEmpty =
          apiAssignedUnitsAfterRestore is! List ||
          apiAssignedUnitsAfterRestore.isEmpty;
      if (stillEmpty) {
        final storedUnitIds = await _secureStorage.getAssignedUnitIds();
        if (storedUnitIds.isNotEmpty) {
          merged['assignedUnits'] = storedUnitIds
              .map((id) => {'id': id})
              .toList();
        } else {
          // Prefer empty array over null for a stable contract.
          merged['assignedUnits'] = <dynamic>[];
        }
      }
    }

    // ── watched/default location fallback ─────────────────────────────────
    // If all location IDs are 0 or null, the API probably stripped them.
    // Try to restore from the last full user snapshot stored at login.
    final allLocationIdsZero = _allLocationIdsZero(merged);
    if (allLocationIdsZero) {
      final storedUserData = await _secureStorage.getUserData();
      if (storedUserData != null && storedUserData.isNotEmpty) {
        try {
          final stored = jsonDecode(storedUserData) as Map<String, dynamic>;
          _restoreLocationField(merged, stored, 'watchedRegionId');
          _restoreLocationField(merged, stored, 'watchedRegionName');
          _restoreLocationField(merged, stored, 'watchedUnitId');
          _restoreLocationField(merged, stored, 'watchedUnitName');
          _restoreLocationField(merged, stored, 'watchedNeighborhoodId');
          _restoreLocationField(merged, stored, 'watchedNeighborhoodName');
          _restoreLocationField(merged, stored, 'watchedZoneId');
          _restoreLocationField(merged, stored, 'watchedZoneName');
          _restoreLocationField(merged, stored, 'defaultRegionId');
          _restoreLocationField(merged, stored, 'defaultRegionName');
          _restoreLocationField(merged, stored, 'defaultUnitId');
          _restoreLocationField(merged, stored, 'defaultUnitName');
          _restoreLocationField(merged, stored, 'defaultNeighborhoodId');
          _restoreLocationField(merged, stored, 'defaultNeighborhoodName');
          _restoreLocationField(merged, stored, 'defaultZoneId');
          _restoreLocationField(merged, stored, 'defaultZoneName');
        } catch (_) {
          // If stored JSON is corrupt, silently ignore.
        }
      }
    }

    return merged;
  }

  bool _allLocationIdsZero(Map<String, dynamic> json) {
    final keys = [
      'watchedRegionId',
      'watchedUnitId',
      'watchedNeighborhoodId',
      'watchedZoneId',
      'defaultRegionId',
      'defaultUnitId',
      'defaultNeighborhoodId',
      'defaultZoneId',
    ];
    for (final key in keys) {
      final value = json[key];
      if (value is num && value > 0) return false;
      if (value is String && value.isNotEmpty && value != '0') return false;
    }
    return true;
  }

  void _restoreLocationField(
    Map<String, dynamic> target,
    Map<String, dynamic> source,
    String key,
  ) {
    final apiValue = target[key];
    final hasApiValue =
        (apiValue is num && apiValue > 0) ||
        (apiValue is String && apiValue.isNotEmpty && apiValue != '0');
    if (!hasApiValue && source.containsKey(key)) {
      target[key] = source[key];
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile(
    UpdateProfileParams params,
  ) async {
    try {
      final responseData = await _apiService.put(
        endPoint: ApiEndpoints.updateProfile,
        data: params.toJson(),
      );
      return Right(UserModelMapper.fromJson(_unwrapUser(responseData)));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure('Error updating profile data'));
    }
  }

  /// Some API deployments wrap the user object in `{"data": {...}}`.
  /// If user fields exist at root, use root; otherwise unwrap from `data`.
  Map<String, dynamic> _unwrapUser(Map<String, dynamic> response) {
    final wrapped = response['data'];
    if (wrapped is Map<String, dynamic> &&
        (wrapped.containsKey('userId') ||
            wrapped.containsKey('id') ||
            wrapped.containsKey('fullName') ||
            wrapped.containsKey('phoneNumber'))) {
      return wrapped;
    }
    return response;
  }
}

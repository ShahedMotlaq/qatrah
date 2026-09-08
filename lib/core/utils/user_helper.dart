// lib/core/utils/user_helper.dart

import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/features/auth/domain/entities/user_role.dart';

/// UserHelper provides quick access to user role and permission checks
/// Centralizes all role-related logic to avoid scattered string comparisons
class UserHelper {
  static final SecureStorage _storage = getIt<SecureStorage>();

  /// Get the current user's role from secure storage
  static Future<UserRole> getUserRole() async {
    final roleString = await _storage.getRole();
    return UserRole.fromString(roleString);
  }

  /// Quick check: is the current user an operator or admin?
  static Future<bool> isOperator() async {
    final role = await getUserRole();
    return role.canManageSchedules;
  }

  /// Quick check: is the current user an admin?
  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role.canAccessAdminPanel;
  }

  /// Quick check: is the current user a citizen only?
  static Future<bool> isCitizen() async {
    final role = await getUserRole();
    return role.isCitizenOnly;
  }

  /// Get the list of unit IDs assigned to the current operator
  /// Returns empty list for non-operators or if no units assigned
  static Future<List<int>> getAssignedUnitIds() async {
    return _storage.getAssignedUnitIds();
  }

  /// Get the list of region IDs assigned to the current employee
  static Future<List<int>> getAssignedRegionIds() async {
    return _storage.getAssignedRegionIds();
  }

  /// Check if the current operator has access to a specific unit
  /// Returns true for admins (they have access to everything)
  /// Returns true for operators if the unit is in their assigned list
  /// Returns false for citizens
  static Future<bool> hasAccessToUnit(int unitId) async {
    final role = await getUserRole();

    // Admins have access to everything
    if (role == UserRole.admin) return true;

    // Operators only have access to assigned units
    if (role == UserRole.operator) {
      return _storage.isAssignedUnit(unitId);
    }

    // Citizens don't have operator access
    return false;
  }

  /// Check if the user can perform operator actions on a specific unit
  /// This is a defensive guard that should be called before any
  /// operator-related API calls (start/end pumping, etc.)
  static Future<bool> canPerformOperatorAction(int unitId) async {
    final isOp = await isOperator();
    if (!isOp) return false;

    return hasAccessToUnit(unitId);
  }
}

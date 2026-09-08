// lib/features/auth/domain/entities/user_role.dart

/// User role enum for type-safe role checking across the application
/// Replaces hardcoded string comparisons like 'ADMIN', 'OPERATOR', 'CITIZEN'
enum UserRole {
  admin('ADMIN'),
  operator('OPERATOR'),
  citizen('CITIZEN');

  const UserRole(this.rawValue);

  /// The raw string value stored in backend and secure storage
  final String rawValue;

  /// Parse from raw string (case-insensitive)
  static UserRole fromString(String? value) {
    if (value == null) return citizen;

    for (final role in values) {
      if (role.rawValue == value.toUpperCase()) {
        return role;
      }
    }
    return citizen; // Default fallback
  }

  /// Check if this role has employee privileges (can manage schedules)
  bool get canManageSchedules => this == admin || this == operator;

  /// Check if this role has full admin access
  bool get canAccessAdminPanel => this == admin;

  /// Check if this is a regular citizen
  bool get isCitizenOnly => this == citizen;
}

// lib/features/notifications/domain/entities/notification_type.dart

/// Domain classification of a notification. Visual mapping (icon/colour) lives
/// in the presentation layer; this enum is pure Dart.
enum NotificationType { start, stop, edit, cancel, pause, resume }

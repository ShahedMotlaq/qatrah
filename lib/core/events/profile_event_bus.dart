// lib/core/events/profile_event_bus.dart

import 'dart:async';

/// A simple event bus to notify other BLoCs when the user profile is updated.
/// This enables cross-BLoC communication without tight coupling.
class ProfileEventBus {
  ProfileEventBus._privateConstructor();

  static final ProfileEventBus instance = ProfileEventBus._privateConstructor();

  final _controller = StreamController<void>.broadcast();

  /// Stream that BLoCs can listen to for profile updates
  Stream<void> get onProfileUpdated => _controller.stream;

  /// Emit an event (call this after successful profile update)
  void notifyProfileUpdated() {
    _controller.add(null);
  }

  /// Dispose the controller
  void dispose() {
    _controller.close();
  }
}

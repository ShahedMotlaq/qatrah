import 'package:flutter/foundation.dart';

/// In-memory lock state for the current Flutter app instance.
///
/// We deliberately do NOT persist `isLocked` across cold starts: the spec
/// requires the lock screen on every kill+relaunch when a refresh token
/// exists. Cold start always begins locked.
class AppLockState extends ChangeNotifier {
  AppLockState();

  bool _employeeUnlocked = false;

  /// True after a successful PIN/biometric unlock in this app run. Reset to
  /// false on long-background resume or on logout.
  bool get isUnlocked => _employeeUnlocked;

  /// Backwards-compatible name for existing call sites.
  bool get isEmployeeUnlocked => _employeeUnlocked;

  /// True iff the app should currently render protected employee screens.
  /// (Not used for citizens.)
  bool get isLocked => !_employeeUnlocked;

  void markUnlocked() {
    if (_employeeUnlocked) return;
    _employeeUnlocked = true;
    notifyListeners();
  }

  /// Lock again — used on long-background resume or after Forgot-PIN /
  /// logout / failed-attempt-cap.
  void markLocked() {
    if (!_employeeUnlocked) return;
    _employeeUnlocked = false;
    notifyListeners();
  }
}

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/auth/app_lock_state.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/routing/routes.dart';

/// Re-locks the app when a lockable session has been backgrounded for
/// longer than [backgroundLockThreshold].
class AppLockLifecycleObserver with WidgetsBindingObserver {
  AppLockLifecycleObserver({
    required AppLockState lockState,
    required SecureAuthStorage authStorage,
    required GoRouter router,
    Duration backgroundLockThreshold = const Duration(minutes: 2),
  }) : _lockState = lockState,
       _storage = authStorage,
       _router = router,
       _threshold = backgroundLockThreshold;

  final AppLockState _lockState;
  final SecureAuthStorage _storage;
  final GoRouter _router;
  final Duration _threshold;

  void attach() => WidgetsBinding.instance.addObserver(this);
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Record the moment the app went to the background.
        _storage.setLastBackgroundedAt(DateTime.now());
      case AppLifecycleState.resumed:
        _maybeLockOnResume();
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _maybeLockOnResume() async {
    // Only matters for sessions that have already unlocked.
    if (!_lockState.isUnlocked) return;
    if (!await _storage.isAppLockSession()) return;
    if (!await _storage.isPinSet()) return;

    final last = await _storage.getLastBackgroundedAt();
    if (last == null) return;
    if (DateTime.now().difference(last) < _threshold) return;

    _lockState.markLocked();
    await _storage.clearLastBackgroundedAt();
    _router.goNamed(Routes.appLock);
  }
}

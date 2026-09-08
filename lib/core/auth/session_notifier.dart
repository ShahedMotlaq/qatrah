import 'dart:async';

import 'package:flutter/foundation.dart';

/// Why an authenticated session ended. Carried on the broadcast stream so
/// listeners can react differently to an involuntary expiry versus an explicit
/// user-initiated sign-out.
enum SessionEndReason {
  /// Tokens were rejected/expired and could not be refreshed (e.g. a 401 the
  /// silent refresh failed to recover from).
  expired,

  /// The user (or the app) deliberately ended the session.
  loggedOut,
}

/// Single source of truth for "the authenticated session just ended".
///
/// It is consumed two ways on purpose:
///
///  * As a [Listenable] (via [ChangeNotifier]) so it can be handed directly to
///    `GoRouter(refreshListenable: ...)`. Every notification re-runs the
///    redirect guard, which performs the forced logout + redirect to `/login`
///    from wherever the user currently is.
///  * As a broadcast [Stream] ([onSessionEnded]) for non-router listeners
///    (Blocs, analytics, logging) that want the [SessionEndReason] payload.
///
/// **Ordering contract:** callers MUST finish wiping secure storage *before*
/// invoking [notifySessionEnded]. The redirect guard reads storage right after
/// being woken; emitting early would let it observe a stale (expired) token and
/// bounce the user back into the app — the classic "login loop".
class SessionNotifier extends ChangeNotifier {
  final StreamController<SessionEndReason> _controller =
      StreamController<SessionEndReason>.broadcast();

  /// Broadcast stream of session-end events, carrying the [SessionEndReason].
  Stream<SessionEndReason> get onSessionEnded => _controller.stream;

  /// Signals that the session has ended. Emits on [onSessionEnded] *and*
  /// notifies [Listenable] consumers (the router) so navigation reacts
  /// immediately.
  ///
  /// Must be called only after secure storage has been fully cleared.
  void notifySessionEnded(SessionEndReason reason) {
    if (_controller.isClosed) return;
    _controller.add(reason);
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

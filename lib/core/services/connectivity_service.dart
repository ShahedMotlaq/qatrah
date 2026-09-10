import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Offline means the OS reports no usable network interface.
///
/// This used to additionally require reaching Cloudflare/Google DNS or an HTTP
/// probe, and treated every failure as "no internet". On networks that block
/// those hosts — or when a bare GET on the API base returned 5xx — the whole
/// app reported offline while the API was perfectly reachable, which is what
/// wedged the profile screen behind a permanent no-internet view.
///
/// ponytail: the interface flag is the only signal we trust. A connected
/// network with no real route (captive portal) now surfaces as a normal API
/// error instead of an offline screen, which is the lesser failure. Probe the
/// app's own API here if captive portals ever need their own message.
bool isOnlineFromConnectivity(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}

class ConnectivityService {
  ConnectivityService();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool? _lastStatus;

  Stream<bool> get statusStream => _statusController.stream;

  Future<void> initialize() async {
    final initialResults = await _connectivity.checkConnectivity();
    _emitConnectionStatus(initialResults);

    _subscription ??= _connectivity.onConnectivityChanged.listen(
      _emitConnectionStatus,
    );
  }

  Future<bool> hasInternetConnection() async {
    final results = await _connectivity.checkConnectivity();
    return isOnlineFromConnectivity(results);
  }

  void _emitConnectionStatus(List<ConnectivityResult> results) {
    final isConnected = isOnlineFromConnectivity(results);
    if (_lastStatus == isConnected) return;

    _lastStatus = isConnected;
    _statusController.add(isConnected);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _statusController.close();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:qatrah/core/config/env.dart';

class ConnectivityService {
  ConnectivityService();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool? _lastStatus;

  Stream<bool> get statusStream => _statusController.stream;

  static const _dnsTargets = [
    'one.one.one.one',
    'dns.google',
    '8.8.8.8',
  ];

  static const _httpTargets = [
    'https://www.google.com/generate_204',
    'https://1.1.1.1/cdn-cgi/trace',
  ];

  Future<void> initialize() async {
    final initialResults = await _connectivity.checkConnectivity();
    await _emitConnectionStatus(initialResults);

    _subscription ??= _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      await _emitConnectionStatus(results);
    });
  }

  Future<bool> hasInternetConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _resolveInternetAccess(results);
  }

  Future<void> _emitConnectionStatus(List<ConnectivityResult> results) async {
    final isConnected = await _resolveInternetAccess(results);
    if (_lastStatus == isConnected) return;

    _lastStatus = isConnected;
    _statusController.add(isConnected);
  }

  Future<bool> _resolveInternetAccess(List<ConnectivityResult> results) async {
    final hasNetworkInterface = results.any(
      (result) => result != ConnectivityResult.none,
    );
    if (!hasNetworkInterface) return false;

    for (final target in _dnsTargets) {
      try {
        final lookup = await InternetAddress.lookup(target);
        if (lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty) {
          return true;
        }
      } on SocketException {
        continue;
      }
    }

    for (final url in _httpTargetsWithApiFirst()) {
      if (await _canReachHttp(url)) return true;
    }

    return false;
  }

  Iterable<String> _httpTargetsWithApiFirst() sync* {
    try {
      yield Env.baseUrl;
    } on Exception {
      // .env may be unavailable in tests; public probes remain as fallback.
    }
    yield* _httpTargets;
  }

  Future<bool> _canReachHttp(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode < 500;
    } on Exception {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _statusController.close();
  }
}

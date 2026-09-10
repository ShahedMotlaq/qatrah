import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/core/services/connectivity_service.dart';

void main() {
  group('isOnlineFromConnectivity', () {
    test('no interface at all is offline', () {
      expect(isOnlineFromConnectivity([ConnectivityResult.none]), isFalse);
      expect(isOnlineFromConnectivity([]), isFalse);
    });

    test('any usable interface is online', () {
      for (final result in [
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
        ConnectivityResult.ethernet,
        ConnectivityResult.vpn,
        ConnectivityResult.other,
      ]) {
        expect(
          isOnlineFromConnectivity([result]),
          isTrue,
          reason: '$result should count as online',
        );
      }
    });

    test('a usable interface alongside none is still online', () {
      expect(
        isOnlineFromConnectivity([
          ConnectivityResult.none,
          ConnectivityResult.wifi,
        ]),
        isTrue,
      );
    });

    // The regression this replaced: a reachable network whose DNS/HTTP probes
    // to Cloudflare and Google were blocked used to report offline, which
    // pinned the profile screen behind a permanent no-internet view.
    test('does not depend on reaching any third-party host', () {
      expect(isOnlineFromConnectivity([ConnectivityResult.mobile]), isTrue);
    });
  });
}

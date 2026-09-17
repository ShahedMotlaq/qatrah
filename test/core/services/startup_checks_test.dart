import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/core/services/maintenance_state_service.dart';
import 'package:qatrah/core/services/version_check_service.dart';

void main() {
  group('ServerState', () {
    test('OK is not maintenance', () {
      final state = ServerState.fromJson({
        'status': 'OK',
        'message': '',
        'retryAfter': 0,
      });

      expect(state.isMaintenance, isFalse);
      expect(state.message, isNull, reason: 'an empty message is no message');
      expect(state.retryAfterSeconds, isNull);
    });

    test('MAINTENANCE carries the message and the wait', () {
      final state = ServerState.fromJson({
        'status': 'MAINTENANCE',
        'message': 'النظام قيد الصيانة',
        'retryAfter': 300,
      });

      expect(state.isMaintenance, isTrue);
      expect(state.message, 'النظام قيد الصيانة');
      expect(state.retryAfterSeconds, 300);
    });

    test('status casing does not matter', () {
      expect(
        ServerState.fromJson({'status': 'maintenance'}).isMaintenance,
        isTrue,
      );
    });

    test('an unreadable body is treated as healthy', () {
      final state = ServerState.fromJson({'unexpected': true});

      expect(state.isMaintenance, isFalse);
      expect(ServerState.ok.isMaintenance, isFalse);
    });
  });

  group('VersionCheckResult', () {
    test('a forced update blocks and points at the store', () {
      final result = VersionCheckResult.fromJson({
        'platform': 'ANDROID',
        'minimumSupportedBuild': 10400,
        'latestBuild': 10500,
        'storeUrl': 'https://play.google.com/store/apps/details?id=x',
        'forceUpdate': true,
        'updateAvailable': true,
      });

      expect(result.forceUpdate, isTrue);
      expect(result.updateAvailable, isTrue);
      expect(result.storeUrl, endsWith('id=x'));
    });

    test('an optional update does not block', () {
      final result = VersionCheckResult.fromJson({
        'forceUpdate': false,
        'updateAvailable': true,
      });

      expect(result.forceUpdate, isFalse);
      expect(result.updateAvailable, isTrue);
    });

    test('missing flags never block the launch', () {
      expect(
        VersionCheckResult.fromJson(<String, dynamic>{}).forceUpdate,
        isFalse,
      );
      expect(VersionCheckResult.none.forceUpdate, isFalse);
    });
  });
}

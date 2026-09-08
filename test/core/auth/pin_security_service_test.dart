import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/core/auth/pin_security_service.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';

import 'fake_secure_storage.dart';

const _testIterations = 1000; // fast for tests

PinSecurityService _buildService(SecureAuthStorage storage, {int seed = 1}) {
  return PinSecurityService(storage, random: Random(seed));
}

void main() {
  group('PinSecurityService.validatePinStrength', () {
    test('rejects wrong length', () {
      expect(PinSecurityService.validatePinStrength('123'), isNotNull);
      expect(PinSecurityService.validatePinStrength('12345'), isNotNull);
      expect(PinSecurityService.validatePinStrength(''), isNotNull);
    });

    test('rejects non-numeric', () {
      expect(PinSecurityService.validatePinStrength('123a'), isNotNull);
      expect(PinSecurityService.validatePinStrength('12 4'), isNotNull);
    });

    test('accepts a valid 4-digit PIN', () {
      expect(PinSecurityService.validatePinStrength('4729'), isNull);
      expect(PinSecurityService.validatePinStrength('5813'), isNull);
    });
  });

  group('PinSecurityService.setPin / verify', () {
    test('verifies a correct PIN', () async {
      final storage = SecureAuthStorage(FakeSecureStorage());
      final svc = _buildService(storage);

      await svc.setPin('4729', iterations: _testIterations);
      final r = await svc.verify('4729');

      expect(r.success, isTrue);
      expect(r.failedAttempts, 0);
      expect(r.lockUntil, isNull);
      expect(await storage.isPinSet(), isTrue);
    });

    test('rejects a wrong PIN', () async {
      final storage = SecureAuthStorage(FakeSecureStorage());
      final svc = _buildService(storage);

      await svc.setPin('4729', iterations: _testIterations);
      final r = await svc.verify('4728');

      expect(r.success, isFalse);
      expect(r.failedAttempts, 1);
      expect(r.shouldClearSession, isFalse);
    });

    test('different salts produce different hashes for same PIN', () async {
      final storageA = SecureAuthStorage(FakeSecureStorage());
      final storageB = SecureAuthStorage(FakeSecureStorage());
      final svcA = _buildService(storageA, seed: 1);
      final svcB = _buildService(storageB, seed: 2);

      await svcA.setPin('4729', iterations: _testIterations);
      await svcB.setPin('4729', iterations: _testIterations);

      final hashA = await storageA.getPinHash();
      final hashB = await storageB.getPinHash();
      final saltA = await storageA.getPinSalt();
      final saltB = await storageB.getPinSalt();

      expect(hashA, isNotNull);
      expect(hashB, isNotNull);
      expect(saltA, isNot(equals(saltB)));
      expect(hashA, isNot(equals(hashB)));
    });

    test(
      'verify returns shouldClearSession when material is missing',
      () async {
        final storage = SecureAuthStorage(FakeSecureStorage());
        final svc = _buildService(storage);

        final r = await svc.verify('4729');

        expect(r.success, isFalse);
        expect(r.shouldClearSession, isTrue);
      },
    );
  });

  group('lockout escalation', () {
    test('5th failure produces a 30s lock', () async {
      final storage = SecureAuthStorage(FakeSecureStorage());
      final svc = _buildService(storage);
      await svc.setPin('4729', iterations: _testIterations);

      for (var i = 0; i < 4; i++) {
        await svc.verify('1112');
      }
      final r5 = await svc.verify('1112');

      expect(r5.failedAttempts, 5);
      expect(r5.lockUntil, isNotNull);
      final delta = r5.lockUntil!.difference(DateTime.now()).inSeconds;
      expect(delta, greaterThan(20));
      expect(delta, lessThanOrEqualTo(30));
    });

    test(
      'verifying while locked returns existing lock without counting',
      () async {
        final storage = SecureAuthStorage(FakeSecureStorage());
        final svc = _buildService(storage);
        await svc.setPin('4729', iterations: _testIterations);

        for (var i = 0; i < 5; i++) {
          await svc.verify('1112');
        }
        final attemptsBefore = await storage.getFailedAttempts();
        final r = await svc.verify('1112');

        expect(r.success, isFalse);
        expect(r.lockUntil, isNotNull);
        expect(r.failedAttempts, attemptsBefore);
      },
    );

    test('10th failure clears session and resets attempts', () async {
      final storage = SecureAuthStorage(FakeSecureStorage());
      final svc = _buildService(storage);
      await svc.setPin('4729', iterations: _testIterations);

      // Forge attempts up to 9 without going through the active-lock guard.
      await storage.setFailedAttempts(9);
      final r = await svc.verify('1112');

      expect(r.failedAttempts, 10);
      expect(r.shouldClearSession, isTrue);
      // Counters are cleared so the user can re-login fresh.
      expect(await storage.getFailedAttempts(), 0);
    });

    test('successful verify resets attempts and clears lock', () async {
      final storage = SecureAuthStorage(FakeSecureStorage());
      final svc = _buildService(storage);
      await svc.setPin('4729', iterations: _testIterations);

      await storage.setFailedAttempts(3);
      final r = await svc.verify('4729');

      expect(r.success, isTrue);
      expect(await storage.getFailedAttempts(), 0);
      expect(await storage.getLockUntil(), isNull);
    });
  });
}

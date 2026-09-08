import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';

/// Outcome of a [PinSecurityService.verify] call.
class PinVerifyResult {
  const PinVerifyResult({
    required this.success,
    required this.failedAttempts,
    this.lockUntil,
    this.shouldClearSession = false,
  });

  /// PIN matched.
  final bool success;

  /// Total wrong attempts persisted after this verification.
  final int failedAttempts;

  /// If non-null, PIN entry is locked until this moment.
  final DateTime? lockUntil;

  /// True after the 10th failed attempt — caller must clear local session
  /// and force the user back to login.
  final bool shouldClearSession;
}

/// Local PIN security:
///  - PBKDF2-HMAC-SHA256 (>= 100k iterations) with a per-device random salt.
///  - Local lockout escalation: 5→30s, 7→5min, 10→clear session.
///
/// PIN material lives in [SecureAuthStorage]. Nothing here is sent to the
/// backend — the PIN is local-only.
class PinSecurityService {
  PinSecurityService(this._storage, {Random? random})
    : _random = random ?? Random.secure();

  final SecureAuthStorage _storage;
  final Random _random;

  static const int defaultIterations = 100000;
  static const int _saltBytes = 16;
  static const int _keyBits = 256;
  static const int pinLength = 4;

  // Lockout policy (per spec):
  static const int _lockAfter5 = 5;
  static const Duration _lock30s = Duration(seconds: 30);
  static const int _lockAfter7 = 7;
  static const Duration _lock5min = Duration(minutes: 5);
  static const int _clearAfter = 10;

  /// Validate PIN format. Any 4 digits are accepted.
  static String? validatePinStrength(String pin) {
    if (pin.length != pinLength) return 'pin_error_length';
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) return 'pin_error_length';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  /// Hash and persist a fresh PIN. Caller must have validated strength first.
  /// Returns the iteration count used, for tests/diagnostics.
  Future<int> setPin(String pin, {int iterations = defaultIterations}) async {
    final salt = _generateSalt();
    final hash = await _pbkdf2(pin, salt, iterations);

    await _storage.savePinMaterial(
      hashBase64: base64Encode(hash),
      saltBase64: base64Encode(salt),
      iterations: iterations,
    );

    return iterations;
  }

  // ---------------------------------------------------------------------------
  // Verify
  // ---------------------------------------------------------------------------

  /// Verify [pin] against persisted material and update lockout state.
  Future<PinVerifyResult> verify(String pin) async {
    // Check active lockout window first.
    final activeLock = await _activeLockUntil();
    if (activeLock != null) {
      return PinVerifyResult(
        success: false,
        failedAttempts: await _storage.getFailedAttempts(),
        lockUntil: activeLock,
      );
    }

    final saltB64 = await _storage.getPinSalt();
    final hashB64 = await _storage.getPinHash();
    final iterations = await _storage.getPinIterations() ?? defaultIterations;

    if (saltB64 == null || hashB64 == null) {
      return const PinVerifyResult(
        success: false,
        failedAttempts: 0,
        shouldClearSession: true,
      );
    }

    final salt = base64Decode(saltB64);
    final expected = base64Decode(hashB64);
    final actual = await _pbkdf2(pin, salt, iterations);
    final ok = _constantTimeEquals(expected, actual);

    if (ok) {
      await _storage.resetFailedAttempts();
      return const PinVerifyResult(success: true, failedAttempts: 0);
    }

    final attempts = (await _storage.getFailedAttempts()) + 1;
    await _storage.setFailedAttempts(attempts);

    if (attempts >= _clearAfter) {
      // Caller is responsible for clearing the actual session.
      await _storage.resetFailedAttempts();
      return PinVerifyResult(
        success: false,
        failedAttempts: attempts,
        shouldClearSession: true,
      );
    }

    DateTime? until;
    if (attempts >= _lockAfter7) {
      until = DateTime.now().add(_lock5min);
    } else if (attempts >= _lockAfter5) {
      until = DateTime.now().add(_lock30s);
    }
    if (until != null) {
      await _storage.setLockUntil(until);
    }

    return PinVerifyResult(
      success: false,
      failedAttempts: attempts,
      lockUntil: until,
    );
  }

  /// Public peek at the current active lockout (or null if entry is allowed).
  Future<DateTime?> activeLockUntil() => _activeLockUntil();

  Future<DateTime?> _activeLockUntil() async {
    final until = await _storage.getLockUntil();
    if (until == null) return null;
    if (DateTime.now().isAfter(until)) {
      await _storage.setLockUntil(null);
      return null;
    }
    return until;
  }

  /// Reset attempt counters and clear any active lock — used after a
  /// successful biometric unlock or a Forgot-PIN flow.
  Future<void> resetAttempts() => _storage.resetFailedAttempts();

  // ---------------------------------------------------------------------------
  // Crypto helpers
  // ---------------------------------------------------------------------------

  Uint8List _generateSalt() {
    final out = Uint8List(_saltBytes);
    for (var i = 0; i < _saltBytes; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }

  Future<List<int>> _pbkdf2(
    String pin,
    List<int> salt,
    int iterations,
  ) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: _keyBits,
    );
    final secretKey = SecretKey(utf8.encode(pin));
    final derived = await pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    return derived.extractBytes();
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

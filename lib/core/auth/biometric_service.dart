import 'package:local_auth/local_auth.dart';
import 'package:qatrah/core/utils/app_logger.dart';

/// Thin wrapper around `local_auth` so the rest of the app doesn't import the
/// platform plugin directly. Biometric is *optional* — every method fails
/// safe (returns false) if the device doesn't support it or the user cancels.
class BiometricService {
  BiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Whether the device has biometric hardware that's enrolled and usable.
  /// Combines `canCheckBiometrics` (hardware/enrolled) with
  /// `isDeviceSupported` (OS supports biometric prompt).
  Future<bool> isSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheck || !supported) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on LocalAuthException catch (e, st) {
      AppLogger.error('BiometricService.isSupported failed: ${e.code}\n$st');
      return false;
    } catch (e, st) {
      AppLogger.error('BiometricService.isSupported error: $e\n$st');
      return false;
    }
  }

  /// Trigger the biometric prompt. Returns true on success, false on failure
  /// or cancel. Never throws.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e, st) {
      AppLogger.error('BiometricService.authenticate failed: ${e.code}\n$st');
      return false;
    } catch (e, st) {
      AppLogger.error('BiometricService.authenticate error: $e\n$st');
      return false;
    }
  }
}

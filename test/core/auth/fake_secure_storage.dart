import 'package:qatrah/core/local_storage/secure_storage.dart';

/// In-memory [SecureStorage] for unit tests so we don't touch the real
/// platform channel. Only the dynamic key APIs used by SecureAuthStorage
/// are wired up — the legacy [DbKeys] APIs are left untouched.
class FakeSecureStorage extends SecureStorage {
  FakeSecureStorage() : super(null, false);

  final Map<String, String> _dynamic = <String, String>{};

  @override
  Future<void> setDynamicValue(String key, String value) async {
    _dynamic[key] = value;
  }

  @override
  Future<String?> getDynamicValue(String key) async => _dynamic[key];

  @override
  Future<void> setDynamicBoolValue(String key, bool value) async {
    _dynamic[key] = value.toString();
  }

  @override
  Future<bool?> getDynamicBoolValue(String key) async {
    final v = _dynamic[key];
    if (v == null) return null;
    return v.toLowerCase() == 'true';
  }

  @override
  Future<void> deleteDynamicValue(String key) async {
    _dynamic.remove(key);
  }
}

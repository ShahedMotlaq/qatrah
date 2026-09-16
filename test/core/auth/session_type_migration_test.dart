import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';

import 'fake_secure_storage.dart';

void main() {
  late FakeSecureStorage storage;
  late SecureAuthStorage auth;

  setUp(() {
    storage = FakeSecureStorage();
    auth = SecureAuthStorage(storage);
  });

  Future<String?> storedType() =>
      storage.getDynamicValue('auth.session_type');

  test('legacy "keycloak" reads as staff and is rewritten in place', () async {
    await auth.setSessionType('keycloak');
    await storage.setDynamicValue('keycloakRoles', '["OPERATOR"]');

    expect(await auth.getSessionType(), SecureAuthStorage.staffSession);
    expect(await storedType(), SecureAuthStorage.staffSession);
    expect(await storage.getDynamicValue('keycloakRoles'), isNull);
    expect(await auth.isStaffSession(), isTrue);
    expect(await auth.isAppLockSession(), isTrue);
  });

  test('legacy "otp" reads as citizen and is rewritten in place', () async {
    await auth.setSessionType('otp');

    expect(await auth.getSessionType(), SecureAuthStorage.citizenSession);
    expect(await storedType(), SecureAuthStorage.citizenSession);
    expect(await auth.isCitizenSession(), isTrue);
    expect(await auth.isAppLockSession(), isTrue);
  });

  test('current labels are left alone', () async {
    await auth.setSessionType(SecureAuthStorage.staffSession);

    expect(await auth.getSessionType(), SecureAuthStorage.staffSession);
    expect(await auth.isCitizenSession(), isFalse);
  });

  test('no session type at all', () async {
    expect(await auth.getSessionType(), isNull);
    expect(await auth.isAppLockSession(), isFalse);
  });

  test('ensureSessionTypeFromRole seeds a pre-key session', () async {
    await storage.setDynamicValue('keycloakRoles', '["ADMIN"]');

    expect(
      await auth.ensureSessionTypeFromRole('OPERATOR'),
      SecureAuthStorage.staffSession,
    );
    expect(await storedType(), SecureAuthStorage.staffSession);
    expect(await storage.getDynamicValue('keycloakRoles'), isNull);

    expect(
      await auth.ensureSessionTypeFromRole('CITIZEN'),
      SecureAuthStorage.staffSession,
      reason: 'an existing session type wins over the role',
    );
  });

  test('ensureSessionTypeFromRole migrates a legacy label first', () async {
    await auth.setSessionType('otp');

    expect(
      await auth.ensureSessionTypeFromRole('CITIZEN'),
      SecureAuthStorage.citizenSession,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/core/routing/route_guards/auth_guard.dart';
import 'package:qatrah/core/routing/routes.dart';

/// Guards the redirect decision table. The case that matters most is
/// "offline with an expired token": storage is intentionally left intact there,
/// so a naive guard sends login → navbar → login until go_router throws
/// "too many redirects" and the user gets a black screen.
void main() {
  Future<String?> resolve({
    required String location,
    bool hasLocalSession = true,
    bool needsLock = false,
    bool serverSession = true,
  }) => AuthGuard.resolve(
    location: location,
    hasLocalSession: hasLocalSession,
    needsLock: needsLock,
    hasServerSession: () async => serverSession,
  );

  group('no local session', () {
    test('public routes render', () async {
      expect(
        await resolve(location: Routes.login, hasLocalSession: false),
        isNull,
      );
    });

    test('protected routes go to login', () async {
      expect(
        await resolve(location: Routes.navbar, hasLocalSession: false),
        Routes.login,
      );
    });

    test('lock-flow routes go to login — nothing to unlock', () async {
      expect(
        await resolve(location: Routes.appLock, hasLocalSession: false),
        Routes.login,
      );
    });
  });

  group('local session, server rejects or is unreachable', () {
    test('login page renders instead of bouncing to navbar', () async {
      expect(
        await resolve(location: Routes.login, serverSession: false),
        isNull,
      );
    });

    test('protected route goes to login', () async {
      expect(
        await resolve(location: Routes.navbar, serverSession: false),
        Routes.login,
      );
    });

    test('login → navbar → login loop cannot form', () async {
      // Walk the redirect chain the way go_router does. It must settle.
      var location = Routes.navbar;
      final seen = <String>[];
      for (var i = 0; i < 5; i++) {
        final next = await resolve(location: location, serverSession: false);
        if (next == null) break;
        seen.add(next);
        location = next;
      }
      expect(seen, [Routes.login], reason: 'settled on login after one hop');
    });
  });

  group('valid session', () {
    test('public route sends the user into the app', () async {
      expect(await resolve(location: Routes.login), Routes.navbar);
    });

    test('protected route renders', () async {
      expect(await resolve(location: Routes.navbar), isNull);
    });

    test('splash is never redirected away from', () async {
      expect(await resolve(location: Routes.splash), isNull);
      expect(
        await resolve(location: Routes.splash, hasLocalSession: false),
        isNull,
      );
    });
  });

  group('lock owed', () {
    test('protected route goes to the lock screen', () async {
      expect(
        await resolve(location: Routes.navbar, needsLock: true),
        Routes.appLock,
      );
    });

    test('the lock screen itself renders', () async {
      expect(
        await resolve(location: Routes.appLock, needsLock: true),
        isNull,
      );
    });

    test('login renders so Forgot-PIN can escape', () async {
      expect(await resolve(location: Routes.login, needsLock: true), isNull);
    });

    test('no server round-trip while a lock is owed', () async {
      var called = false;
      final result = await AuthGuard.resolve(
        location: Routes.navbar,
        hasLocalSession: true,
        needsLock: true,
        hasServerSession: () async {
          called = true;
          return true;
        },
      );
      expect(result, Routes.appLock);
      expect(called, isFalse);
    });

    test('pin setup route is not bounced to navbar', () async {
      expect(await resolve(location: Routes.createPin), isNull);
    });
  });
}

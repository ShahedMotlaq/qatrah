import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/core/services/version_check_service.dart';
import 'package:qatrah/features/splash/presentation/widgets/optional_update_dialog.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

Future<void> _open(WidgetTester tester, VersionCheckResult version) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showOptionalUpdateDialog(context, version),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('canOfferUpdate', () {
    test('needs an available update and somewhere to send the user', () {
      const withUrl = VersionCheckResult(
        forceUpdate: false,
        updateAvailable: true,
        storeUrl: 'https://play.google.com/store/apps/details?id=x',
      );
      expect(withUrl.canOfferUpdate, isTrue);

      const noUrl = VersionCheckResult(
        forceUpdate: false,
        updateAvailable: true,
      );
      expect(noUrl.canOfferUpdate, isFalse);

      expect(VersionCheckResult.none.canOfferUpdate, isFalse);
    });

    test('a forced update is never offered as optional', () {
      const forced = VersionCheckResult(
        forceUpdate: true,
        updateAvailable: true,
        storeUrl: 'https://example.test/app',
      );

      expect(
        forced.canOfferUpdate,
        isFalse,
        reason: 'forceUpdate goes to the blocking page instead',
      );
    });
  });

  group('showOptionalUpdateDialog', () {
    testWidgets('shows the version and notes the server sent', (tester) async {
      await _open(
        tester,
        const VersionCheckResult(
          forceUpdate: false,
          updateAvailable: true,
          storeUrl: 'https://example.test/app',
          latestVersionName: '1.5.0',
          releaseNotes: 'Faster schedules screen.',
        ),
      );

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('Version 1.5.0'), findsOneWidget);
      expect(find.text('Faster schedules screen.'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
    });

    testWidgets('omits the optional lines when absent', (tester) async {
      await _open(
        tester,
        const VersionCheckResult(
          forceUpdate: false,
          updateAvailable: true,
          storeUrl: 'https://example.test/app',
        ),
      );

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.textContaining('Version '), findsNothing);
    });

    testWidgets('Later dismisses it', (tester) async {
      await _open(
        tester,
        const VersionCheckResult(
          forceUpdate: false,
          updateAvailable: true,
          storeUrl: 'https://example.test/app',
        ),
      );

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsNothing);
    });

    testWidgets('no url, no dialog', (tester) async {
      await _open(
        tester,
        const VersionCheckResult(forceUpdate: false, updateAvailable: true),
      );

      expect(find.text('Update Available'), findsNothing);
    });
  });
}

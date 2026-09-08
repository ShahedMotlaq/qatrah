import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/auth/fresh_install_marker.dart';
import 'package:qatrah/core/notification/notification_service.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/firebase_options.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    // debugPrint, not log(): dart:developer log() goes to the VM service and
    // is silently dropped in AOT builds, so release crashes never reach
    // logcat. debugPrint reaches it in every build mode.
    debugPrint('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait-up only (no landscape/rotation).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('Firebase initialized successfully');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    log('FCM background handler registered');
  } catch (e, stackTrace) {
    log('Error initializing Firebase: $e', stackTrace: stackTrace);
  }

  try {
    await dotenv.load();
    log('Environment variables loaded successfully');
  } catch (e) {
    log('Error loading .env file: $e');
  }

  await ScreenUtil.ensureScreenSize();

  FlutterError.onError = (details) {
    debugPrint(
      '[FlutterError] ${details.exceptionAsString()}\n${details.stack}',
    );
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformDispatcher] $error\n$stack');
    return true;
  };

  Bloc.observer = const AppBlocObserver();

  await setupServiceLocator();

  try {
    final freshInstallMarker = getIt<FreshInstallMarker>();
    await freshInstallMarker.ensureMarker();
    // Covers in-place upgraders, whose install marker is already set so
    // ensureMarker() returns early without purging the legacy plaintext PIN.
    await freshInstallMarker.ensureLegacyPinPurged();
  } catch (e, stackTrace) {
    log('Error running FreshInstallMarker: $e', stackTrace: stackTrace);
  }

  try {
    await getIt<NotificationService>().initialize();
    log('NotificationService initialized successfully');

    getIt<NotificationService>().printTokenForTesting().catchError((e) {
      log(
        'Could not print token during init (will be available later): $e',
        name: 'FCM',
      );
    });
  } catch (e, stackTrace) {
    log('Error initializing NotificationService: $e', stackTrace: stackTrace);
  }

  await dotenv.load();
  runZonedGuarded(
    () async {
      runApp(await builder());
    },
    (error, stack) {
      debugPrint('[Zone] $error\n$stack');
    },
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  log('[Background] Message received', name: 'FCM_BG');
  log('[Background] Message ID: ${message.messageId}', name: 'FCM_BG');
  log('[Background] Title: ${message.notification?.title}', name: 'FCM_BG');
  log('[Background] Body: ${message.notification?.body}', name: 'FCM_BG');
  log('[Background] DATA: ${message.data}', name: 'FCM_BG');
}

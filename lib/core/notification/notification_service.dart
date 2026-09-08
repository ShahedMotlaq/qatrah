import 'dart:async';
import 'dart:developer' as dev;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/settings_storage_service.dart';
import 'package:qatrah/features/auth/domain/repositories/i_auth_repository.dart';

class NotificationService {
  NotificationService._privateConstructor();

  static final NotificationService instance =
      NotificationService._privateConstructor();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  SecureStorage? _secureStorage;
  IAuthRepository? _authRepository;
  SettingsStorageService? _settingsStorage;

  bool _isInitialized = false;
  String? _currentToken;
  final StreamController<RemoteMessage> _notificationStreamController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get notificationStream =>
      _notificationStreamController.stream;
  String? get currentToken => _currentToken;

  static const String generalNotificationsChannel = 'general_notification';
  static const String pumpingNotificationsChannel = 'pumping_notifications';

  static AndroidNotificationChannel getChannelById(String channelId) {
    switch (channelId) {
      case generalNotificationsChannel:
        return const AndroidNotificationChannel(
          generalNotificationsChannel,
          'General Updates',
          description: 'General notifications and updates',
          importance: Importance.max,
          enableLights: true,
          sound: RawResourceAndroidNotificationSound('general_sound'),
        );
      case pumpingNotificationsChannel:
        return const AndroidNotificationChannel(
          pumpingNotificationsChannel,
          'Pumping Alerts',
          description: 'Water pumping alerts and notifications',
          importance: Importance.max,
          enableLights: true,
          sound: RawResourceAndroidNotificationSound('pumping_start_sound'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );
      default:
        return const AndroidNotificationChannel(
          generalNotificationsChannel,
          'General Updates',
          description: 'General notifications and updates',
          importance: Importance.max,
          enableLights: true,
          sound: RawResourceAndroidNotificationSound('general_sound'),
        );
    }
  }

  static List<AndroidNotificationChannel> getAllChannels() {
    return [
      getChannelById(generalNotificationsChannel),
      getChannelById(pumpingNotificationsChannel),
    ];
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    _secureStorage = getIt<SecureStorage>();
    _authRepository = getIt<IAuthRepository>();
    _settingsStorage = getIt<SettingsStorageService>();

    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();

    _isInitialized = true;
    dev.log('NotificationService initialized successfully', name: 'FCM');
  }

  Future<void> _initializeFirebaseMessaging() async {
    // The permission prompt is NOT requested here: initialize() runs from
    // bootstrap() before runApp(), and on Android 13+ a runtime prompt raised
    // before the Flutter activity is drawing is unreliable — it can be dropped
    // without ever showing. The splash screen calls
    // [ensureNotificationPermission] once the first frame is up.
    await _handleTokenManagement();
    _messaging.onTokenRefresh.listen(_onTokenRefresh);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTapped);
    await _checkInitialMessage();
  }

  /// Asks the user for notification permission, once the UI is on screen.
  ///
  /// Call this from the first visible screen — never from bootstrap() — so the
  /// system dialog is raised against a live activity. Returns whether
  /// notifications are permitted.
  ///
  /// Android < 13 has no POST_NOTIFICATIONS runtime permission: the request
  /// resolves as granted immediately and no dialog is shown. Android 13+ shows
  /// the dialog on the first call only; later calls just report the stored
  /// answer, so calling this on every launch is safe.
  Future<bool> ensureNotificationPermission() async {
    try {
      final settings = await _messaging.requestPermission(criticalAlert: true);
      dev.log(
        'Notification permission status: ${settings.authorizationStatus}',
        name: 'FCM',
      );
    } catch (e) {
      dev.log('Error requesting FCM permission: $e', name: 'FCM');
    }

    if (defaultTargetPlatform != TargetPlatform.android) return true;

    var granted = false;
    try {
      final status = await Permission.notification.request();
      granted = status.isGranted;
      dev.log('📱 Android notification permission: $status', name: 'FCM');
      if (granted) await _settingsStorage?.setNotificationsEnabled(true);
    } catch (e) {
      dev.log('❌ Error requesting notification permission: $e', name: 'FCM');
    }

    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      dev.log(
        'Error requesting local notifications permission: $e',
        name: 'FCM',
      );
    }

    return granted;
  }

  Future<void> _handleTokenManagement() async {
    try {
      final notificationsEnabled =
          await _settingsStorage?.isNotificationsEnabled() ?? true;
      if (!notificationsEnabled) {
        await deleteTokenOnLogout();
        return;
      }

      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        await _sendTokenToBackend(_currentToken!);
      }
    } catch (e) {
      dev.log('Error getting FCM token: $e', name: 'FCM');
    }
  }

  Future<void> _onTokenRefresh(String newToken) async {
    final notificationsEnabled =
        await _settingsStorage?.isNotificationsEnabled() ?? true;
    if (!notificationsEnabled) return;

    _currentToken = newToken;
    await _sendTokenToBackend(newToken);
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final isLoggedIn = await _secureStorage?.getLoggedInStatus() ?? false;
      if (!isLoggedIn) return;
      final result = await _authRepository?.updateFcmToken(token);
      result?.fold(
        (failure) => dev.log(
          'Failed to update FCM token on backend: ${failure.errMessage}',
          name: 'FCM',
        ),
        (_) =>
            dev.log('FCM token updated on backend successfully', name: 'FCM'),
      );
    } catch (e) {
      dev.log('Error sending FCM token to backend: $e', name: 'FCM');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation == null) return;

    for (final channel in NotificationService.getAllChannels()) {
      await androidImplementation.createNotificationChannel(channel);
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    _notificationStreamController.add(message);
    await _showLocalNotification(message);
    _showToastNotification(message);
  }

  void _showToastNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'إشعار';
    final body = message.notification?.body ?? '';
    dev.log('Toast notification: $title - $body', name: 'FCM');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notificationsEnabled =
        await _settingsStorage?.isNotificationsEnabled() ?? true;
    if (!notificationsEnabled) return;

    final notification = message.notification;
    final title = notification?.title ?? 'Qatrah';
    final body = notification?.body ?? '';
    final channelId = _resolveForegroundChannelId(message);
    final channelConfig = NotificationService.getChannelById(channelId);

    final soundEnabled = await _settingsStorage?.isSoundEnabled() ?? true;
    final vibrationEnabled =
        await _settingsStorage?.isVibrationEnabled() ?? true;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelConfig.name,
      channelDescription: channelConfig.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      sound: soundEnabled ? channelConfig.sound : null,
      enableVibration: vibrationEnabled,
      enableLights: true,
      icon: 'ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('ic_notification'),
      ticker: title,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
    );

    try {
      await _localNotifications.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      dev.log('Error showing local notification: $e', name: 'FCM');
    }
  }

  String _resolveForegroundChannelId(RemoteMessage message) {
    final androidChannelId = message.notification?.android?.channelId;
    final dataChannelId = message.data['android_channel_id']?.toString();
    final dataChannelName = message.data['channel']?.toString();
    final incomingChannelId =
        (androidChannelId?.isNotEmpty ?? false
                ? androidChannelId
                : dataChannelId?.isNotEmpty ?? false
                ? dataChannelId
                : dataChannelName?.isNotEmpty ?? false
                ? dataChannelName
                : null)
            ?.trim()
            .toLowerCase();

    if (incomingChannelId == null || incomingChannelId.isEmpty) {
      return generalNotificationsChannel;
    }

    if (incomingChannelId == generalNotificationsChannel ||
        incomingChannelId.contains('general')) {
      return generalNotificationsChannel;
    }

    if (incomingChannelId == pumpingNotificationsChannel ||
        incomingChannelId.contains('pumping') ||
        incomingChannelId.contains('pump')) {
      return pumpingNotificationsChannel;
    }

    return generalNotificationsChannel;
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _onNotificationTapped(initialMessage);
    }
  }

  Future<void> _onNotificationTapped(RemoteMessage message) async {
    await _navigateFromPayload(message.data);
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    dev.log('Local notification tapped: ${response.payload}', name: 'FCM');
  }

  Future<void> _navigateFromPayload(Map<String, dynamic> data) async {
    if (data.isEmpty) return;

    final type = data['type']?.toString() ?? '';
    final id = data['id']?.toString();

    switch (type) {
      case 'schedule':
      case 'pumping_schedule':
        await _navigateToSchedule(id, data);
      case 'complaint':
        await _navigateToComplaint(id, data);
      case 'notification':
      case 'pumping':
      case 'pumping_start':
      case 'PUMPING_STARTED':
      case 'PUMPING_ENDED':
      case 'PUMPING_PAUSED':
      case 'PUMPING_RESUMED':
        await _navigateToNotifications();
      case 'feedback':
      case 'water_feedback':
        await _navigateToFeedback(id, data);
      case 'profile':
        await _navigateToProfile();
      default:
        await _navigateToNotifications();
    }
  }

  Future<void> _navigateToSchedule(
    String? id,
    Map<String, dynamic> data,
  ) async {
    dev.log('Navigate to schedule: $id', name: 'FCM');
    await _requestNavigationAfterAppOpen(() async {
      // Navigation will be handled by the app router based on deep link data
      return data;
    });
  }

  Future<void> _navigateToComplaint(
    String? id,
    Map<String, dynamic> data,
  ) async {
    dev.log('Navigate to complaint: $id', name: 'FCM');
    await _requestNavigationAfterAppOpen(() async {
      return data;
    });
  }

  Future<void> _navigateToNotifications() async {
    dev.log('Navigate to notifications page', name: 'FCM');
    await _requestNavigationAfterAppOpen(() async {
      return {'navigateToNotifications': true};
    });
  }

  Future<void> _navigateToFeedback(
    String? id,
    Map<String, dynamic> data,
  ) async {
    dev.log('Navigate to feedback: $id', name: 'FCM');
    await _requestNavigationAfterAppOpen(() async {
      return data;
    });
  }

  Future<void> _navigateToProfile() async {
    dev.log('Navigate to profile', name: 'FCM');
    await _requestNavigationAfterAppOpen(() async {
      return {'navigateToProfile': true};
    });
  }

  Future<void> _requestNavigationAfterAppOpen(
    Future<Map<String, dynamic>> Function() navData,
  ) async {
    // Store the navigation request to be processed when the app is fully loaded
    final data = await navData();
    // This will be handled by the main app initialization code
    dev.log('Navigation request queued: $data', name: 'FCM');
  }

  Future<void> uploadTokenAfterLogin() async {
    if (!_isInitialized) {
      await initialize();
    }
    await _handleTokenManagement();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsStorage?.setNotificationsEnabled(enabled);
    if (enabled) {
      await _handleTokenManagement();
      return;
    }
    await deleteTokenOnLogout();
    await _localNotifications.cancelAll();
  }

  Future<void> deleteTokenOnLogout() async {
    try {
      final isLoggedIn = await _secureStorage?.getLoggedInStatus() ?? false;
      if (isLoggedIn) {
        final result = await _authRepository?.removeFcmToken();
        result?.fold(
          (failure) => dev.log(
            'Failed to remove FCM token on backend: ${failure.errMessage}',
            name: 'FCM',
          ),
          (_) =>
              dev.log('FCM token removed on backend successfully', name: 'FCM'),
        );
      }
      await _messaging.deleteToken();
      _currentToken = null;
    } catch (e) {
      dev.log('Error deleting FCM token: $e', name: 'FCM');
    }
  }

  void dispose() {
    _notificationStreamController.close();
  }

  Future<String?> getTestingToken() async {
    final token = await _messaging.getToken();
    dev.log('[Testing Token] $token', name: 'FCM');
    return token;
  }

  Future<void> printTokenForTesting() async {
    final token = await getTestingToken();
    if (token != null) {
      dev.log(token, name: 'FCM TOKEN');
    } else {
      dev.log('Failed to get FCM token', name: 'FCM TOKEN');
    }
  }
}

import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'notification_service.dart';
import '../models/bot_event.dart';

// ═══════════════════════════════════════════════════════════════
// Background message handler — must be top-level
// ═══════════════════════════════════════════════════════════════

/// Called when a push notification arrives while the app is terminated
/// or in the background. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main.dart.
  // Background messages are displayed automatically by the system tray
  // if they contain a `notification` payload. Data-only messages
  // can be processed here if needed in the future.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

// ═══════════════════════════════════════════════════════════════
// Push Notification Service
// ═══════════════════════════════════════════════════════════════

/// Manages Firebase Cloud Messaging (FCM) for background push notifications.
///
/// Responsibilities:
/// - Request & refresh FCM device token
/// - Register token with backend so the server can send pushes
/// - Forward foreground FCM messages to [NotificationService] for display
class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiClient _api;
  final NotificationService _notificationService;

  String? _currentToken;
  bool _initialized = false;

  PushNotificationService({
    required ApiClient api,
    required NotificationService notificationService,
  }) : _api = api,
       _notificationService = notificationService;

  /// Initialize FCM — request permission, get token, set up listeners.
  ///
  /// Call this after the user is authenticated so the token can be
  /// registered with the backend immediately.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (iOS shows a system prompt, Android 13+ needs POST_NOTIFICATIONS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Notifications denied by user');
      return;
    }

    // Get the FCM token
    try {
      _currentToken = await _messaging.getToken();
      debugPrint('[FCM] Token: ${_currentToken?.substring(0, 20)}...');
      if (_currentToken != null) {
        await _registerTokenWithBackend(_currentToken!);
      }
    } catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
    }

    // Listen for token refresh (happens when app is reinstalled, user
    // clears data, or Firebase rotates the token)
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token refreshed');
      _currentToken = newToken;
      await _registerTokenWithBackend(newToken);
    });

    // Foreground messages — display via local notification service
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps that opened the app from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if the app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // On iOS, set foreground presentation options
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    debugPrint('[FCM] Initialized');
  }

  /// Register the FCM token with the backend for server-sent pushes.
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await _api.post(
        '/auth/device-token',
        data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
      debugPrint('[FCM] Token registered with backend');
    } catch (e) {
      // Non-fatal — backend push won't work but local notifications still do
      debugPrint('[FCM] Failed to register token: $e');
    }
  }

  /// Handle a foreground FCM message by converting it to a local notification.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    // If the message contains a notification payload, show it locally
    if (notification != null) {
      _notificationService.showPushNotification(
        title: notification.title ?? 'Aura',
        body: notification.body ?? '',
        payload: data['type'] ?? '',
      );
      return;
    }

    // Data-only message — try to map to a BotEvent for consistent handling
    final eventType = data['type'];
    if (eventType != null) {
      final botEvent = BotEvent(
        type: eventType,
        botId: data['botId'] ?? '',
        userId: 0,
        timestamp: DateTime.now(),
        data: data,
      );
      _notificationService.handleBotEvent(botEvent);
    }
  }

  /// Handle a notification tap that opened the app.
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tap: ${message.data}');
    // Future: navigate to relevant screen based on message.data
  }

  /// Unregister the device token on logout.
  Future<void> unregister() async {
    if (_currentToken == null) return;
    try {
      await _api.delete('/auth/device-token');
      debugPrint('[FCM] Token unregistered');
    } catch (e) {
      debugPrint('[FCM] Failed to unregister token: $e');
    }
    _currentToken = null;
    _initialized = false;
  }

  /// The current FCM token (if available).
  String? get token => _currentToken;
}

// ═══════════════════════════════════════════════════════════════
// Riverpod Provider
// ═══════════════════════════════════════════════════════════════

/// Push notification service provider — depends on ApiClient and NotificationService.
final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final api = ref.read(apiClientProvider);
  final notificationService = ref.read(notificationServiceProvider);
  return PushNotificationService(
    api: api,
    notificationService: notificationService,
  );
});

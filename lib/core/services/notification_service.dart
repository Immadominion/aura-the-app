import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bot_event.dart';

// ═══════════════════════════════════════════════════════════════
// Notification Channels (Android)
// ═══════════════════════════════════════════════════════════════

/// Android notification channel configuration.
///
/// Channels are registered once at init and persist across sessions.
/// Users can override importance per-channel in system settings.
class _Channels {
  static const positionAlerts = 'sage_position_alerts';
  static const positionAlertsName = 'Position Alerts';
  static const positionAlertsDesc =
      'Notifications when LP positions are opened or closed';

  static const botAlerts = 'sage_bot_alerts';
  static const botAlertsName = 'Bot Alerts';
  static const botAlertsDesc =
      'Bot lifecycle events — start, stop, errors, emergency';

  static const systemAlerts = 'sage_system_alerts';
  static const systemAlertsName = 'System';
  static const systemAlertsDesc = 'Scan results and general updates';
}

// ═══════════════════════════════════════════════════════════════
// Preference Keys
// ═══════════════════════════════════════════════════════════════

/// SharedPreferences keys for per-event-type notification toggles.
///
/// All default to `true` — the user opts out, not in.
class NotificationPrefKeys {
  static const prefix = 'notif_';
  static const positionOpened = '${prefix}position_opened';
  static const positionClosed = '${prefix}position_closed';
  static const botStarted = '${prefix}bot_started';
  static const botStopped = '${prefix}bot_stopped';
  static const botError = '${prefix}bot_error';
  static const scanCompleted = '${prefix}scan_completed';

  /// All toggle keys, ordered for the settings UI.
  static const allKeys = [
    positionOpened,
    positionClosed,
    botStarted,
    botStopped,
    botError,
    scanCompleted,
  ];

  /// Human-readable label for each key.
  static String label(String key) => switch (key) {
    positionOpened => 'Position Opened',
    positionClosed => 'Position Closed',
    botStarted => 'Bot Started',
    botStopped => 'Bot Stopped',
    botError => 'Bot Errors',
    scanCompleted => 'Scan Results',
    _ => key,
  };

  /// Description for each key shown as subtitle.
  static String description(String key) => switch (key) {
    positionOpened => 'When a new LP position is opened',
    positionClosed => 'When a position is closed (PnL included)',
    botStarted => 'When a trading bot starts',
    botStopped => 'When a bot stops or is paused',
    botError => 'Engine errors and emergency stops',
    scanCompleted => 'Market scan results with entries',
    _ => '',
  };
}

// ═══════════════════════════════════════════════════════════════
// NotificationService
// ═══════════════════════════════════════════════════════════════

/// Manages local notifications for real-time bot events.
///
/// Designed around three responsibilities:
/// 1. **Platform init** — registers channels, requests permissions.
/// 2. **Event → notification mapping** — converts [BotEvent] to a
///    platform notification with title, body, channel, and payload.
/// 3. **Preference storage** — per-event-type toggles persisted in
///    [SharedPreferences] so users control what they see.
///
/// Usage:
/// ```dart
/// final service = ref.read(notificationServiceProvider);
/// await service.initialize();
/// service.handleBotEvent(event);
/// ```
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  /// Whether [initialize] has completed successfully.
  bool get isInitialized => _initialized;

  // ────────────────────────────────────────────
  // Initialization
  // ────────────────────────────────────────────

  /// Initialize the plugin, register Android channels, and optionally
  /// request permissions on iOS / Android 13+.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const darwinSettings = DarwinInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
      );

      final result = await _plugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
        ),
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: _backgroundHandler,
      );

      if (result != true) {
        debugPrint('[Notifications] Plugin init returned false');
        return false;
      }

      if (Platform.isAndroid) {
        await _createAndroidChannels();
      }

      _initialized = true;
      debugPrint('[Notifications] Initialized');
      return true;
    } catch (e, st) {
      debugPrint('[Notifications] Init error: $e\n$st');
      return false;
    }
  }

  // ────────────────────────────────────────────
  // Permissions
  // ────────────────────────────────────────────

  /// Request notification permissions.
  ///
  /// On iOS this shows the system permission dialog.
  /// On Android 13+ this requests POST_NOTIFICATIONS.
  /// Returns `true` if granted.
  Future<bool> requestPermission() async {
    try {
      if (Platform.isIOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await android?.requestNotificationsPermission();
        return granted ?? false;
      }

      return true; // Other platforms
    } catch (e) {
      debugPrint('[Notifications] Permission request failed: $e');
      return false;
    }
  }

  /// Check whether the OS-level notification permission is enabled.
  Future<bool> arePermissionsGranted() async {
    try {
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.areNotificationsEnabled() ?? false;
      }

      if (Platform.isIOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final settings = await ios?.checkPermissions();
        return settings?.isEnabled ?? false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ────────────────────────────────────────────
  // Preference Toggles
  // ────────────────────────────────────────────

  /// Whether notifications for [prefKey] are enabled.
  /// Defaults to `true` (opt-out model).
  Future<bool> isEnabled(String prefKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKey) ?? true;
  }

  /// Set the notification toggle for [prefKey].
  Future<void> setEnabled(String prefKey, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, enabled);
  }

  /// Load all toggle states at once (for the settings UI).
  Future<Map<String, bool>> loadAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final key in NotificationPrefKeys.allKeys)
        key: prefs.getBool(key) ?? true,
    };
  }

  // ────────────────────────────────────────────
  // Event → Notification
  // ────────────────────────────────────────────

  /// Process a [BotEvent] and fire a local notification if the user
  /// has that event type enabled.
  ///
  /// This is the main entry point — call it from [EventService] for
  /// every incoming SSE event.
  Future<void> handleBotEvent(BotEvent event) async {
    if (!_initialized) return;

    final (prefKey, title, body, channel) = _mapEvent(event);
    if (prefKey == null) return; // Unknown or non-notifiable event type

    // Check user preference
    final enabled = await isEnabled(prefKey);
    if (!enabled) return;

    await _show(
      title: title!,
      body: body!,
      channelId: channel!.$1,
      channelName: channel.$2,
      channelDesc: channel.$3,
      importance: channel.$4,
      payload: '${event.type}|${event.botId}',
    );
  }

  /// Map a [BotEvent] to notification display parameters.
  ///
  /// Returns `(prefKey, title, body, (channelId, name, desc, importance))`.
  /// Returns all-null tuple for events we don't notify on.
  (
    String? prefKey,
    String? title,
    String? body,
    (String, String, String, Importance)? channel,
  )
  _mapEvent(BotEvent event) {
    final data = event.data ?? {};

    if (event.isPositionOpened) {
      final pool = data['pool'] as String? ?? 'Unknown pool';
      return (
        NotificationPrefKeys.positionOpened,
        '📈 Position Opened',
        'Entered $pool',
        (
          _Channels.positionAlerts,
          _Channels.positionAlertsName,
          _Channels.positionAlertsDesc,
          Importance.high,
        ),
      );
    }

    if (event.isPositionClosed) {
      final pool = data['pool'] as String? ?? 'Unknown pool';
      final pnl = data['pnlSol'];
      final result = data['result'] as String? ?? '';
      final pnlStr = pnl != null
          ? ' (${result == 'WIN' ? '+' : ''}${(pnl as num).toStringAsFixed(4)} SOL)'
          : '';
      final emoji = result == 'WIN' ? '🟢' : '🔴';
      return (
        NotificationPrefKeys.positionClosed,
        '$emoji Position Closed — $result',
        '$pool$pnlStr',
        (
          _Channels.positionAlerts,
          _Channels.positionAlertsName,
          _Channels.positionAlertsDesc,
          Importance.high,
        ),
      );
    }

    if (event.isBotStarted) {
      return (
        NotificationPrefKeys.botStarted,
        '▶️ Bot Started',
        'Trading engine is running',
        (
          _Channels.botAlerts,
          _Channels.botAlertsName,
          _Channels.botAlertsDesc,
          Importance.defaultImportance,
        ),
      );
    }

    if (event.isBotStopped) {
      return (
        NotificationPrefKeys.botStopped,
        '⏹️ Bot Stopped',
        'Trading engine stopped',
        (
          _Channels.botAlerts,
          _Channels.botAlertsName,
          _Channels.botAlertsDesc,
          Importance.defaultImportance,
        ),
      );
    }

    if (event.isBotError) {
      final error = data['error'] as String? ?? 'Unknown error';
      return (
        NotificationPrefKeys.botError,
        '⚠️ Bot Error',
        error,
        (
          _Channels.botAlerts,
          _Channels.botAlertsName,
          _Channels.botAlertsDesc,
          Importance.high,
        ),
      );
    }

    if (event.isScanCompleted) {
      final eligible = data['eligible'] as int? ?? 0;
      final entered = data['entered'] as int? ?? 0;
      return (
        NotificationPrefKeys.scanCompleted,
        '🔍 Scan Complete',
        '$entered entries from $eligible eligible pools',
        (
          _Channels.systemAlerts,
          _Channels.systemAlertsName,
          _Channels.systemAlertsDesc,
          Importance.low,
        ),
      );
    }

    // Non-notifiable event types (stats:updated, position:updated, etc.)
    return (null, null, null, null);
  }

  // ────────────────────────────────────────────
  // Internal
  // ────────────────────────────────────────────

  Future<void> _show({
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDesc,
    required Importance importance,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: importance,
      priority: importance == Importance.high
          ? Priority.high
          : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF5B8DEF), // Sage accent (dark theme)
      enableVibration: importance == Importance.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      DateTime.now().microsecondsSinceEpoch % 0x7FFFFFFF,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: darwinDetails),
      payload: payload,
    );

    debugPrint('[Notifications] Showed: $title');
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _Channels.positionAlerts,
        _Channels.positionAlertsName,
        description: _Channels.positionAlertsDesc,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
    );

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _Channels.botAlerts,
        _Channels.botAlertsName,
        description: _Channels.botAlertsDesc,
        importance: Importance.defaultImportance,
      ),
    );

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _Channels.systemAlerts,
        _Channels.systemAlertsName,
        description: _Channels.systemAlertsDesc,
        importance: Importance.low,
      ),
    );

    debugPrint('[Notifications] Android channels registered');
  }

  /// Handle foreground notification taps.
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[Notifications] Tapped: ${response.payload}');
    // Future: navigate to bot detail or position detail based on payload
  }

  /// Handle background notification taps (must be top-level or static).
  @pragma('vm:entry-point')
  static void _backgroundHandler(NotificationResponse response) {
    debugPrint('[Notifications] Background tap: ${response.payload}');
  }

  /// Cancel all displayed notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

// ═══════════════════════════════════════════════════════════════
// Riverpod Providers
// ═══════════════════════════════════════════════════════════════

/// Singleton [NotificationService] — auto-initializes on first read.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();

  // Fire-and-forget init — permissions are requested separately from settings UI
  service.initialize();

  return service;
});

/// Loads all notification preference toggles.
///
/// Invalidate this when a toggle changes so the UI rebuilds:
/// ```dart
/// ref.invalidate(notificationPrefsProvider);
/// ```
final notificationPrefsProvider = FutureProvider<Map<String, bool>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.loadAllPreferences();
});

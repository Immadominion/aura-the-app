import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bot_event.dart';
import 'api_client.dart';
import 'notification_service.dart';

/// SSE (Server-Sent Events) service for real-time bot event streaming.
///
/// Connects to `GET /events/stream` on the aura-backend.
/// Automatically reconnects on disconnect with exponential backoff.
/// Broadcasts [BotEvent]s to all listeners via a [StreamController].
class EventService {
  final ApiClient _api;

  StreamSubscription<SSEModel>? _sseSubscription;
  final _controller = StreamController<BotEvent>.broadcast();
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 10;
  bool _disposed = false;
  bool _connected = false;
  bool _connecting = false;
  bool _paused = false;
  bool _authFailed = false;

  EventService(this._api);

  /// Stream of all bot events for the authenticated user.
  Stream<BotEvent> get events => _controller.stream;

  /// Whether the SSE connection is currently active.
  bool get isConnected => _connected;

  /// Connect to the SSE stream.
  /// Requires the user to be authenticated (JWT must be set).
  void connect() {
    if (_disposed) return;
    if (_connected || _connecting) return; // Already connected or in progress
    if (!_api.isAuthenticated) {
      debugPrint('[SSE] Not authenticated — skipping connect');
      return;
    }

    // Reset auth failed flag on fresh connect (e.g. after token refresh)
    _authFailed = false;
    _connecting = true;

    _disconnect();

    final baseUrl = _api.dio.options.baseUrl;
    final url = '$baseUrl/events/stream';
    final token = _api.accessToken;

    debugPrint('[SSE] Connecting to $url');

    try {
      final stream = SSEClient.subscribeToSSE(
        method: SSERequestType.GET,
        url: url,
        header: {
          'Authorization': 'Bearer $token',
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      );

      _sseSubscription = stream.listen(
        (event) {
          if (_disposed) return;

          // Mark connected on first event
          if (!_connected) {
            _connected = true;
            _connecting = false;
            _reconnectAttempts = 0;
            debugPrint('[SSE] Connected');
          }

          // Skip heartbeats and connection confirmations
          if (event.event == 'heartbeat' || event.event == 'connected') {
            debugPrint('[SSE] ${event.event}');
            return;
          }

          // Parse bot event
          try {
            final data = jsonDecode(event.data ?? '{}') as Map<String, dynamic>;

            // Detect auth errors from the response and stop retrying
            if (data['error'] != null &&
                data['message'] != null &&
                data['message'].toString().contains('Authentication failed')) {
              debugPrint(
                '[SSE] Auth error — stopping reconnect, will try token refresh',
              );
              _authFailed = true;
              _disconnect();
              _tryRefreshAndReconnect();
              return;
            }

            final botEvent = BotEvent(
              type: event.event ?? 'unknown',
              botId: data['botId'] as String? ?? '',
              userId: 0, // Server doesn't send userId in event data
              timestamp: data['timestamp'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      data['timestamp'] as int,
                    )
                  : DateTime.now(),
              data: data,
            );

            debugPrint(
              '[SSE] Event: ${botEvent.type} (bot: ${botEvent.botId})',
            );
            _controller.add(botEvent);
          } catch (e) {
            debugPrint('[SSE] Failed to parse event: $e');
          }
        },
        onError: (error) {
          debugPrint('[SSE] Stream error: $error');
          _connected = false;
          _connecting = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[SSE] Stream closed');
          _connected = false;
          _connecting = false;
          if (!_disposed) {
            _scheduleReconnect();
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[SSE] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  /// Pause the SSE connection (e.g. when app goes to background).
  /// Saves battery and avoids stale connections.
  void pause() {
    if (_paused || _disposed) return;
    _paused = true;
    _disconnect();
    debugPrint('[SSE] Paused — app backgrounded');
  }

  /// Resume the SSE connection (e.g. when app returns to foreground).
  void resume() {
    if (!_paused || _disposed) return;
    _paused = false;
    debugPrint('[SSE] Resuming — app foregrounded');
    connect();
  }

  /// Whether the SSE stream is paused (app backgrounded).
  bool get isPaused => _paused;

  /// Schedule a reconnection with exponential backoff.
  void _scheduleReconnect() {
    if (_disposed || _paused || _authFailed) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[SSE] Max reconnect attempts reached — giving up');
      return;
    }

    _reconnectTimer?.cancel();

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, max 30s
    final delay = Duration(seconds: (1 << _reconnectAttempts).clamp(1, 30));
    _reconnectAttempts++;

    debugPrint(
      '[SSE] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)',
    );

    _reconnectTimer = Timer(delay, () {
      if (!_disposed) connect();
    });
  }

  /// Try refreshing the access token and reconnecting.
  Future<void> _tryRefreshAndReconnect() async {
    if (_disposed || _paused) return;
    try {
      final refreshed = await _api.refreshAccessToken();
      if (refreshed) {
        debugPrint('[SSE] Token refreshed — reconnecting');
        _authFailed = false;
        _reconnectAttempts = 0;
        connect();
      } else {
        debugPrint(
          '[SSE] Token refresh failed — SSE disabled until next login',
        );
      }
    } catch (e) {
      debugPrint('[SSE] Token refresh error: $e');
    }
  }

  /// Disconnect from the SSE stream without disposing.
  void _disconnect() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _reconnectTimer?.cancel();
    _connected = false;
    _connecting = false;
  }

  /// Permanently dispose the service.
  void dispose() {
    _disposed = true;
    _disconnect();
    _controller.close();
  }
}

// ═══════════════════════════════════════════════════════════════
// Riverpod Providers
// ═══════════════════════════════════════════════════════════════

/// Singleton EventService provider.
final eventServiceProvider = Provider<EventService>((ref) {
  final api = ref.read(apiClientProvider);
  final service = EventService(api);

  ref.onDispose(() => service.dispose());

  return service;
});

/// Stream provider for bot events — widgets can watch this.
final botEventStreamProvider = StreamProvider<BotEvent>((ref) {
  final service = ref.watch(eventServiceProvider);

  // Auto-connect when this provider is first watched
  if (!service.isConnected) {
    service.connect();
  }

  return service.events;
});

/// Bridges SSE events to local notifications.
///
/// Read this provider once (e.g., in the app shell after auth) to
/// activate the notification pipeline. Each incoming [BotEvent] is
/// forwarded to [NotificationService.handleBotEvent], which checks
/// the user's per-event-type preferences before showing anything.
final notificationBridgeProvider = Provider<void>((ref) {
  final eventService = ref.watch(eventServiceProvider);
  final notifService = ref.read(notificationServiceProvider);

  // Auto-connect SSE if not already connected
  if (!eventService.isConnected) {
    eventService.connect();
  }

  // Forward every SSE event to the notification service
  final sub = eventService.events.listen((event) {
    notifService.handleBotEvent(event);
  });

  ref.onDispose(() => sub.cancel());
});

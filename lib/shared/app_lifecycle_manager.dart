import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/connectivity_provider.dart';
import '../core/repositories/position_repository.dart';
import '../core/services/auth_service.dart';
import '../core/services/event_service.dart';

/// Observes app lifecycle (foreground/background) and connectivity changes
/// to pause / resume SSE streaming and avoid wasted battery / stale data.
///
/// Wrap your top-level widget tree with this:
/// ```dart
/// AppLifecycleManager(child: AppShell(...))
/// ```
class AppLifecycleManager extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleManager> createState() =>
      _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends ConsumerState<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final eventService = ref.read(eventServiceProvider);

    switch (state) {
      case AppLifecycleState.resumed:
        // App is visible & interactive — reconnect SSE
        eventService.resume();
        // Reconcile positions: catch any orphaned or closed-outside-app
        // positions. Fire-and-forget — errors are silently swallowed
        // because this is a best-effort background check.
        _reconcilePositions();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // App is backgrounded — tear down SSE to save battery
        eventService.pause();
        break;
      case AppLifecycleState.inactive:
        // Brief transition (e.g. incoming call overlay) — keep connection
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch connectivity — reconnect SSE and re-validate auth on restore
    ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
      final wasOnline = prev?.value ?? true;
      final isOnline = next.value ?? true;
      final eventService = ref.read(eventServiceProvider);

      if (!wasOnline && isOnline) {
        debugPrint('[Lifecycle] Network restored');

        // Reconnect SSE if app is in foreground.
        if (!eventService.isPaused) {
          debugPrint('[Lifecycle] Reconnecting SSE');
          eventService.connect();
        }

        // Re-validate auth state — the cached user may be stale or
        // the tokens may have expired while offline.
        ref.read(authStateProvider.notifier).revalidate();
      }
    });

    // ── Activate the SSE → local notification bridge ──
    // Reading this provider sets up a StreamSubscription that forwards
    // every BotEvent to NotificationService.handleBotEvent().
    // Notifications are gated by per-event-type user preferences.
    ref.watch(notificationBridgeProvider);

    return widget.child;
  }

  /// Fire-and-forget position reconciliation.
  /// Only runs if the user is authenticated — otherwise a no-op.
  void _reconcilePositions() {
    final authState = ref.read(authStateProvider);
    if (authState.value == null) return; // not logged in

    ref
        .read(positionRepositoryProvider)
        .reconcile()
        .then((result) {
          final reconciled = result['reconciled'] ?? 0;
          final orphaned = result['orphaned'] ?? 0;
          if (reconciled > 0 || orphaned > 0) {
            debugPrint(
              '[Lifecycle] Reconciled $reconciled closed, $orphaned orphaned positions',
            );
          }
        })
        .catchError((e) {
          // Silently ignore — this is best-effort.
          debugPrint('[Lifecycle] Reconciliation skipped: $e');
        });
  }
}

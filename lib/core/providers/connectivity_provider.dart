import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device currently has network connectivity.
///
/// Uses `connectivity_plus` to monitor WiFi / mobile / ethernet.
/// Returns `false` when ConnectivityResult.none, `true` otherwise.
///
/// Note: This checks *interface* availability, not actual reachability.
/// A device may report WiFi connected but fail to reach the backend.
final connectivityProvider = StreamNotifierProvider<ConnectivityNotifier, bool>(
  ConnectivityNotifier.new,
);

class ConnectivityNotifier extends StreamNotifier<bool> {
  @override
  Stream<bool> build() {
    final connectivity = Connectivity();

    // Emit initial state, then listen for changes
    return connectivity.onConnectivityChanged.map(_isOnline);
  }

  static bool _isOnline(List<ConnectivityResult> results) {
    // connectivity_plus v6 returns a List<ConnectivityResult>
    if (results.isEmpty) return false;
    return !results.every((r) => r == ConnectivityResult.none);
  }
}

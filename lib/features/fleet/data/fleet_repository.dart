import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aura/core/services/api_client.dart';
import 'package:aura/features/fleet/models/fleet_models.dart';

/// Repository for Fleet leaderboard API calls.
class FleetRepository {
  final ApiClient _api;

  FleetRepository(this._api);

  /// Fetch the public leaderboard.
  /// [sort] can be 'pnl', 'winRate', or 'trades'.
  Future<List<FleetEntry>> getLeaderboard({
    String sort = 'pnl',
    int limit = 20,
  }) async {
    final response = await _api.get(
      '/fleet/leaderboard',
      queryParameters: {'sort': sort, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['leaderboard'] as List;
    return list
        .map((e) => FleetEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch platform-wide aggregate stats.
  Future<FleetStats> getStats() async {
    final response = await _api.get('/fleet/stats');
    final data = response.data as Map<String, dynamic>;
    return FleetStats.fromJson(data['stats'] as Map<String, dynamic>);
  }

  /// Toggle bot visibility on the leaderboard.
  Future<void> setVisibility({
    required String botId,
    required bool isPublic,
  }) async {
    await _api.put(
      '/fleet/visibility',
      data: {'botId': botId, 'isPublic': isPublic},
    );
  }
}

/// Riverpod providers.
final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  return FleetRepository(ref.watch(apiClientProvider));
});

final fleetLeaderboardProvider =
    FutureProvider.family<List<FleetEntry>, String>((ref, sort) async {
      return ref.watch(fleetRepositoryProvider).getLeaderboard(sort: sort);
    });

final fleetStatsProvider = FutureProvider<FleetStats>((ref) async {
  return ref.watch(fleetRepositoryProvider).getStats();
});

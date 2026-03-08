import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/position.dart';
import '../services/api_client.dart';

/// Repository for position data from `/position/*` endpoints.
class PositionRepository {
  final ApiClient _api;

  PositionRepository(this._api);

  /// All active positions across all user's bots.
  Future<List<Position>> getActivePositions() async {
    final response = await _api.get('/position/active');
    final data = response.data as Map<String, dynamic>;
    final list = data['positions'] as List<dynamic>;
    return list
        .map((e) => Position.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Closed positions (paginated).
  Future<PositionHistoryPage> getHistory({
    int limit = 20,
    int offset = 0,
    String? botId,
  }) async {
    final params = <String, dynamic>{'limit': limit, 'offset': offset};
    if (botId != null) params['botId'] = botId;

    final response = await _api.get(
      '/position/history',
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['positions'] as List<dynamic>;
    return PositionHistoryPage(
      positions: list
          .map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int,
      offset: data['offset'] as int,
      limit: data['limit'] as int,
    );
  }

  /// All positions for a specific bot.
  Future<List<Position>> getBotPositions(String botId) async {
    final response = await _api.get('/position/bot/$botId');
    final data = response.data as Map<String, dynamic>;
    final list = data['positions'] as List<dynamic>;
    return list
        .map((e) => Position.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Single position detail (merges live + DB data).
  Future<Position> getPosition(String positionId) async {
    final response = await _api.get('/position/$positionId');
    final data = response.data as Map<String, dynamic>;
    return Position.fromJson(data['position'] as Map<String, dynamic>);
  }

  /// Close an active position.
  /// Returns the realized P&L in SOL.
  Future<double> closePosition(
    String positionId, {
    String reason = 'USER_CLOSE',
  }) async {
    final response = await _api.post(
      '/position/$positionId/close',
      data: {'reason': reason},
    );
    final data = response.data as Map<String, dynamic>;
    return (data['pnlSol'] as num?)?.toDouble() ?? 0.0;
  }

  /// Reconcile active positions against on-chain state.
  /// Marks positions as closed or orphaned if they no longer match.
  /// Returns {reconciled, orphaned, total} counts.
  Future<Map<String, dynamic>> reconcile() async {
    final response = await _api.post('/position/reconcile', data: {});
    return response.data as Map<String, dynamic>;
  }
}

/// Paginated history response.
class PositionHistoryPage {
  final List<Position> positions;
  final int total;
  final int offset;
  final int limit;

  const PositionHistoryPage({
    required this.positions,
    required this.total,
    required this.offset,
    required this.limit,
  });

  bool get hasMore => offset + positions.length < total;
}

// ═══════════════════════════════════════════════════════════════
// Riverpod Providers
// ═══════════════════════════════════════════════════════════════

/// Repository provider.
final positionRepositoryProvider = Provider<PositionRepository>((ref) {
  return PositionRepository(ref.read(apiClientProvider));
});

/// Active positions across all bots (auto-refresh).
final activePositionsProvider =
    AsyncNotifierProvider<ActivePositionsNotifier, List<Position>>(() {
      return ActivePositionsNotifier();
    });

class ActivePositionsNotifier extends AsyncNotifier<List<Position>> {
  @override
  Future<List<Position>> build() async {
    final repo = ref.read(positionRepositoryProvider);
    return repo.getActivePositions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(positionRepositoryProvider).getActivePositions(),
    );
  }
}

/// Positions for a specific bot.
final botPositionsProvider = FutureProvider.family<List<Position>, String>((
  ref,
  botId,
) async {
  final repo = ref.read(positionRepositoryProvider);
  return repo.getBotPositions(botId);
});

/// Single position detail.
final positionDetailProvider = FutureProvider.family<Position, String>((
  ref,
  positionId,
) async {
  final repo = ref.read(positionRepositoryProvider);
  return repo.getPosition(positionId);
});

/// Position history (paginated) — first page.
final positionHistoryProvider = FutureProvider<PositionHistoryPage>((
  ref,
) async {
  final repo = ref.read(positionRepositoryProvider);
  return repo.getHistory();
});

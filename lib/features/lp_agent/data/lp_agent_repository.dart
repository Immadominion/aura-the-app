/// Repository for the Aura backend's `/lp-agent/*` proxy endpoints.
///
/// LP Agent is the canonical pool-discovery, position-listing, and
/// liquidity transaction-building service used across the app. The
/// backend already wraps the upstream API (auth + owner enforcement +
/// rate limits + 503 graceful-degradation), so this repository is a
/// thin Dio wrapper.
///
/// Phase A (this file) implements:
///   • status()
///   • discoverPools()
///   • getOpeningPositions()
///
/// Phase B (next sprint) will add the Zap-In / Zap-Out tx-building
/// methods. Their backend endpoints are already shipped — we simply
/// haven't built the MWA sign-preview UI yet.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aura/core/services/api_client.dart';
import '../models/lp_pool.dart';
import '../models/lp_position.dart';

/// Sort options for [LpAgentRepository.discoverPools].
enum LpPoolSort {
  volume24h('vol_24h'),
  liquidity('tvl'),
  fees24h('fee_24h');

  const LpPoolSort(this.apiKey);
  final String apiKey;
}

class LpAgentRepository {
  final ApiClient _api;

  LpAgentRepository(this._api);

  // ────────────────────────────────────────────
  // Status
  // ────────────────────────────────────────────

  /// Returns whether the backend has an LP Agent API key configured.
  /// When `false`, every other call will return empty/throw 503 — the
  /// UI should render a degraded state instead of an error.
  Future<bool> isConfigured() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/lp-agent/status');
      return (res.data?['configured'] as bool?) ?? false;
    } on DioException {
      return false;
    }
  }

  // ────────────────────────────────────────────
  // Pool discovery
  // ────────────────────────────────────────────

  /// Discover pools, sorted by [sortBy] desc.
  ///
  /// Returns an empty list (rather than throwing) on a 503 from the
  /// backend so callers can render a graceful "LP Agent unavailable"
  /// state. All other errors propagate.
  Future<List<LpPool>> discoverPools({
    int page = 1,
    int pageSize = 25,
    LpPoolSort sortBy = LpPoolSort.volume24h,
    String chain = 'SOL',
    double? minLiquidity,
    double? minVolume24h,
    String? search,
  }) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/lp-agent/pools/discover',
        queryParameters: {
          'chain': chain,
          'page': page,
          'pageSize': pageSize,
          'sortBy': sortBy.apiKey,
          'sortOrder': 'desc',
          if (minLiquidity != null) 'min_liquidity': minLiquidity,
          if (minVolume24h != null) 'min_volume_24h': minVolume24h,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      // Backend wraps as { success, data: { data: [...] } } — the inner
      // shape mirrors the upstream LP Agent envelope.
      final outer = res.data?['data'];
      final rows = switch (outer) {
        Map m when m['data'] is List => m['data'] as List,
        List l => l,
        _ => const [],
      };

      return rows
          .whereType<Map>()
          .map((row) => LpPool.fromJson(Map<String, dynamic>.from(row)))
          .whereType<LpPool>()
          .toList(growable: false);
    } on ApiException catch (e) {
      if (e.statusCode == 503) return const [];
      rethrow;
    }
  }

  // ────────────────────────────────────────────
  // Pool detail
  // ────────────────────────────────────────────

  /// Raw pool info — UI does not consume the full shape today, so this
  /// returns the decoded JSON. Wrap in a model when a detail screen is
  /// built.
  Future<Map<String, dynamic>> getPoolInfo(String poolId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/lp-agent/pools/$poolId/info',
    );
    final data = res.data?['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  // ────────────────────────────────────────────
  // Owner-scoped: opening positions
  // ────────────────────────────────────────────

  /// External LP positions held by [owner] that the upstream LP Agent
  /// is tracking. Backend enforces `owner == jwt.walletAddress` (403).
  Future<List<LpPosition>> getOpeningPositions({
    required String owner,
    int pageSize = 50,
  }) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/lp-agent/positions/opening',
        queryParameters: {'owner': owner, 'pageSize': pageSize},
      );
      final outer = res.data?['data'];
      final rows = switch (outer) {
        Map m when m['data'] is List => m['data'] as List,
        List l => l,
        _ => const [],
      };
      return rows
          .whereType<Map>()
          .map((row) => LpPosition.fromJson(Map<String, dynamic>.from(row)))
          .whereType<LpPosition>()
          .toList(growable: false);
    } on ApiException catch (e) {
      if (e.statusCode == 503) return const [];
      rethrow;
    }
  }
}

/// Provider — single instance bound to the app's [ApiClient].
final lpAgentRepositoryProvider = Provider<LpAgentRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return LpAgentRepository(api);
});

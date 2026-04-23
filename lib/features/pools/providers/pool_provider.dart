import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aura/features/lp_agent/data/lp_agent_repository.dart';
import 'package:aura/features/lp_agent/models/lp_pool.dart';
import 'package:aura/features/pools/models/pool_candidate.dart';

/// Live pool candidate provider — backed by `/lp-agent/pools/discover`.
///
/// Replaces the static stub list (2026-04-23). Returns an empty list
/// (graceful) when the LP Agent integration is unconfigured server-side
/// so the screen can show an "LP Agent unavailable" empty state instead
/// of a hard error.
///
/// Per-pool ML scoring is not surfaced today: the in-process MLPredictor
/// only runs when a bot's strategy is active. We synthesise a deterministic
/// ranking score from `volume / TVL` (capital-efficiency proxy) so the UI
/// has a meaningful sort signal until per-pool batch scoring lands.
final poolCandidatesProvider = FutureProvider<List<PoolCandidate>>((ref) async {
  final repo = ref.read(lpAgentRepositoryProvider);
  final pools = await repo.discoverPools(
    pageSize: 25,
    sortBy: LpPoolSort.volume24h,
  );
  return pools.map(_toCandidate).toList(growable: false);
});

PoolCandidate _toCandidate(LpPool p) {
  // Capital-efficiency proxy capped at 1.0. (Real ML probability arrives
  // when batch pool scoring is wired into the backend.)
  final efficiency = (p.volumeToLiquidity.clamp(0, 5)) / 5;
  final score = efficiency.toDouble();

  // Tier thresholds keep a sane visual distribution: top → enter,
  // middle → watch, bottom → skip.
  final rec = score >= 0.7
      ? PoolRecommendation.enter
      : score >= 0.35
      ? PoolRecommendation.watch
      : PoolRecommendation.skip;

  return PoolCandidate(
    id: p.address,
    pairName: p.pairName,
    score: score,
    mlConfidence: score, // Mirrors score until per-pool inference lands.
    tvlUsd: p.tvlUsd,
    volume24hUsd: p.volume24hUsd,
    binStep: p.binStep,
    recommendation: rec,
  );
}

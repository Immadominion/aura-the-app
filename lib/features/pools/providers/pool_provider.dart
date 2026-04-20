import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aura/features/pools/models/pool_candidate.dart';

/// Phase 15 (audit §6.1) — Pool candidate provider.
///
/// Stub data source. When the LP Agent pool endpoints are wired in
/// (audit §10), swap the synchronous placeholder below for a live
/// repository call. Keeping the surface async-safe means the screen
/// never has to change.
final poolCandidatesProvider = FutureProvider<List<PoolCandidate>>((ref) async {
  // Simulate a brief network round-trip so the loading state is visible
  // during integration. Remove once a real repository is wired.
  await Future<void>.delayed(const Duration(milliseconds: 250));
  return _stubCandidates;
});

const _stubCandidates = <PoolCandidate>[
  PoolCandidate(
    id: 'sol-usdc-1',
    pairName: 'SOL / USDC',
    score: 0.92,
    mlConfidence: 0.88,
    tvlSol: 12_400,
    volume24hSol: 38_500,
    binStep: 25,
    recommendation: PoolRecommendation.enter,
  ),
  PoolCandidate(
    id: 'jto-sol-1',
    pairName: 'JTO / SOL',
    score: 0.81,
    mlConfidence: 0.79,
    tvlSol: 4_200,
    volume24hSol: 9_300,
    binStep: 50,
    recommendation: PoolRecommendation.enter,
  ),
  PoolCandidate(
    id: 'wif-sol-1',
    pairName: 'WIF / SOL',
    score: 0.74,
    mlConfidence: 0.71,
    tvlSol: 2_900,
    volume24hSol: 11_800,
    binStep: 100,
    recommendation: PoolRecommendation.watch,
  ),
  PoolCandidate(
    id: 'bonk-sol-1',
    pairName: 'BONK / SOL',
    score: 0.66,
    mlConfidence: 0.63,
    tvlSol: 1_700,
    volume24hSol: 6_400,
    binStep: 100,
    recommendation: PoolRecommendation.watch,
  ),
  PoolCandidate(
    id: 'jup-usdc-1',
    pairName: 'JUP / USDC',
    score: 0.58,
    mlConfidence: 0.55,
    tvlSol: 5_300,
    volume24hSol: 4_100,
    binStep: 25,
    recommendation: PoolRecommendation.watch,
  ),
  PoolCandidate(
    id: 'pyth-sol-1',
    pairName: 'PYTH / SOL',
    score: 0.41,
    mlConfidence: 0.39,
    tvlSol: 880,
    volume24hSol: 1_200,
    binStep: 50,
    recommendation: PoolRecommendation.skip,
  ),
  PoolCandidate(
    id: 'rndr-usdc-1',
    pairName: 'RNDR / USDC',
    score: 0.34,
    mlConfidence: 0.31,
    tvlSol: 540,
    volume24hSol: 780,
    binStep: 100,
    recommendation: PoolRecommendation.skip,
  ),
];

/// Phase 15 (audit §6.1) — Pool Browser candidate row.
///
/// A pool the model is currently scoring. Read-only in v1 — proves Aura
/// is *thinking* even when it isn't trading. The model will be backed
/// by the LP Agent pool endpoints (audit §10) once that integration
/// lands; for now the screen reads from a stub provider.
library;

enum PoolRecommendation { enter, watch, skip }

extension PoolRecommendationX on PoolRecommendation {
  String get label => switch (this) {
    PoolRecommendation.enter => 'ENTER',
    PoolRecommendation.watch => 'WATCH',
    PoolRecommendation.skip => 'SKIP',
  };
}

class PoolCandidate {
  final String id;
  final String pairName; // e.g. "SOL/USDC"
  final double score; // 0..1, model-assigned ranking score
  final double mlConfidence; // 0..1
  final double tvlSol; // current TVL in SOL
  final double volume24hSol; // 24h volume in SOL
  final int binStep;
  final PoolRecommendation recommendation;

  const PoolCandidate({
    required this.id,
    required this.pairName,
    required this.score,
    required this.mlConfidence,
    required this.tvlSol,
    required this.volume24hSol,
    required this.binStep,
    required this.recommendation,
  });
}

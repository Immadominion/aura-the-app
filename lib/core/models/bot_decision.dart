// BotDecision model — maps to backend `bot_decisions` table.
// Captures per-pool evaluation outcomes from each scan cycle.

enum DecisionVerdict { entered, watched, skipped }

class ScoreBreakdown {
  final double volumeScore;
  final double liquidityScore;
  final double feeScore;
  final double momentumScore;
  final double totalScore;

  const ScoreBreakdown({
    required this.volumeScore,
    required this.liquidityScore,
    required this.feeScore,
    required this.momentumScore,
    required this.totalScore,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      volumeScore: (json['volumeScore'] as num?)?.toDouble() ?? 0,
      liquidityScore: (json['liquidityScore'] as num?)?.toDouble() ?? 0,
      feeScore: (json['feeScore'] as num?)?.toDouble() ?? 0,
      momentumScore: (json['momentumScore'] as num?)?.toDouble() ?? 0,
      totalScore: (json['totalScore'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BotDecision {
  final int id;
  final String botId;
  final String scanId;
  final String poolAddress;
  final String poolName;
  final DecisionVerdict decision;
  final String reason;
  final double? ruleScore;
  final double? mlProbability;
  final ScoreBreakdown? scoreBreakdown;
  final Map<String, dynamic>? features;
  final String? positionId;
  final DateTime timestamp;

  const BotDecision({
    required this.id,
    required this.botId,
    required this.scanId,
    required this.poolAddress,
    required this.poolName,
    required this.decision,
    required this.reason,
    this.ruleScore,
    this.mlProbability,
    this.scoreBreakdown,
    this.features,
    this.positionId,
    required this.timestamp,
  });

  factory BotDecision.fromJson(Map<String, dynamic> json) {
    return BotDecision(
      id: json['id'] as int,
      botId: json['botId'] as String,
      scanId: json['scanId'] as String,
      poolAddress: json['poolAddress'] as String,
      poolName: json['poolName'] as String,
      decision: DecisionVerdict.values.firstWhere(
        (e) => e.name == json['decision'],
        orElse: () => DecisionVerdict.skipped,
      ),
      reason: json['reason'] as String? ?? '',
      ruleScore: (json['ruleScore'] as num?)?.toDouble(),
      mlProbability: (json['mlProbability'] as num?)?.toDouble(),
      scoreBreakdown: json['scoreBreakdown'] != null
          ? ScoreBreakdown.fromJson(
              json['scoreBreakdown'] as Map<String, dynamic>,
            )
          : null,
      features: json['features'] as Map<String, dynamic>?,
      positionId: json['positionId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

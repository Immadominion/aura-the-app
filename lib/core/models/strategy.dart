/// Strategy preset model — maps to backend `strategy_presets` table.
class StrategyPreset {
  final int id;
  final String name;
  final String? description;
  final bool isSystem;
  final double entryScoreThreshold;
  final double minVolume24h;
  final double minLiquidity;
  final double maxLiquidity;
  final double positionSizeSOL;
  final int maxConcurrentPositions;
  final int defaultBinRange;
  final double profitTargetPercent;
  final double stopLossPercent;
  final int maxHoldTimeMinutes;
  final double maxDailyLossSOL;
  final int cooldownMinutes;

  const StrategyPreset({
    required this.id,
    required this.name,
    this.description,
    required this.isSystem,
    required this.entryScoreThreshold,
    required this.minVolume24h,
    required this.minLiquidity,
    required this.maxLiquidity,
    required this.positionSizeSOL,
    required this.maxConcurrentPositions,
    required this.defaultBinRange,
    required this.profitTargetPercent,
    required this.stopLossPercent,
    required this.maxHoldTimeMinutes,
    required this.maxDailyLossSOL,
    required this.cooldownMinutes,
  });

  factory StrategyPreset.fromJson(Map<String, dynamic> json) =>
      StrategyPreset(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        isSystem: json['isSystem'] == 1 || json['isSystem'] == true,
        entryScoreThreshold:
            (json['entryScoreThreshold'] as num).toDouble(),
        minVolume24h: (json['minVolume24h'] as num?)?.toDouble() ?? 1000,
        minLiquidity: (json['minLiquidity'] as num?)?.toDouble() ?? 5000,
        maxLiquidity: (json['maxLiquidity'] as num?)?.toDouble() ?? 500000,
        positionSizeSOL: (json['positionSizeSOL'] as num).toDouble(),
        maxConcurrentPositions: json['maxConcurrentPositions'] as int,
        defaultBinRange: (json['defaultBinRange'] as num?)?.toInt() ?? 10,
        profitTargetPercent:
            (json['profitTargetPercent'] as num).toDouble(),
        stopLossPercent: (json['stopLossPercent'] as num).toDouble(),
        maxHoldTimeMinutes: json['maxHoldTimeMinutes'] as int,
        maxDailyLossSOL: (json['maxDailyLossSOL'] as num?)?.toDouble() ?? 5.0,
        cooldownMinutes: json['cooldownMinutes'] as int,
      );
}

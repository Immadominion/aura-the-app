// Risk profile definitions for the Setup Wizard.
//
// Maps each profile to concrete bot config values used
// during bot creation.

enum SetupPath { sageAi, custom }

enum RiskProfile { conservative, balanced, aggressive }

/// Execution mode chosen in the final setup step.
enum ExecutionMode { simulation, live }

/// Risk guardrails — maps a profile to concrete bot parameters.
class RiskConfig {
  final double positionSizeSOL;
  final double maxDailyLossSOL;
  final double profitTargetPercent;
  final double stopLossPercent;
  final int maxConcurrentPositions;
  final int maxHoldTimeMinutes;
  final double entryScoreThreshold;

  const RiskConfig({
    required this.positionSizeSOL,
    required this.maxDailyLossSOL,
    required this.profitTargetPercent,
    required this.stopLossPercent,
    required this.maxConcurrentPositions,
    required this.maxHoldTimeMinutes,
    required this.entryScoreThreshold,
  });
}

/// Defaults for the Custom Strategy entry-condition sliders.
class CustomEntryDefaults {
  final double minVolume24h;
  final double minLiquidity;
  final double maxLiquidity;
  final int defaultBinRange;
  final int cooldownMinutes;

  const CustomEntryDefaults({
    this.minVolume24h = 1000,
    this.minLiquidity = 100,
    this.maxLiquidity = 1000000,
    this.defaultBinRange = 10,
    this.cooldownMinutes = 79,
  });
}

const riskConfigs = {
  RiskProfile.conservative: RiskConfig(
    positionSizeSOL: 0.5,
    maxDailyLossSOL: 1.5,
    profitTargetPercent: 5,
    stopLossPercent: 4,
    maxConcurrentPositions: 3,
    maxHoldTimeMinutes: 120,
    entryScoreThreshold: 200,
  ),
  RiskProfile.balanced: RiskConfig(
    positionSizeSOL: 1.0,
    maxDailyLossSOL: 3.0,
    profitTargetPercent: 8,
    stopLossPercent: 6,
    maxConcurrentPositions: 5,
    maxHoldTimeMinutes: 240,
    entryScoreThreshold: 150,
  ),
  RiskProfile.aggressive: RiskConfig(
    positionSizeSOL: 2.0,
    maxDailyLossSOL: 8.0,
    profitTargetPercent: 12,
    stopLossPercent: 10,
    maxConcurrentPositions: 8,
    maxHoldTimeMinutes: 360,
    entryScoreThreshold: 100,
  ),
};

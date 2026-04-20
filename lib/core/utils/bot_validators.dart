/// Centralized validation constants and helpers for bot financial parameters.
///
/// These constraints MUST mirror the backend Zod schema in
/// `aura-backend/src/routes/bot.ts` (`createBotSchema`).
///
/// ⚠️ FINANCIAL SYSTEM: Any change here must be synchronized with the backend.
library;

/// Validation constraints matching backend `createBotSchema`.
abstract final class BotConstraints {
  // ── Name ──
  static const int nameMinLength = 1;
  static const int nameMaxLength = 64;

  // ── Position Size (SOL) ──
  static const double positionSizeMin = 0.01; // > 0
  static const double positionSizeMax = 100.0;

  // ── Entry Score Threshold (%) ──
  static const double entryThresholdMin = 1.0; // > 0
  static const double entryThresholdMax = 500.0; // reasonable UI cap

  // ── Max Concurrent Positions ──
  static const int maxConcurrentMin = 1;
  static const int maxConcurrentMax = 20;

  // ── Profit Target (%) ──
  static const double profitTargetMin = 0.1; // > 0
  static const double profitTargetMax = 100.0;

  // ── Stop Loss (%) ──
  static const double stopLossMin = 0.1; // > 0
  static const double stopLossMax = 100.0;

  // ── Max Hold Time (minutes) ──
  static const int maxHoldTimeMin = 1; // > 0
  static const int maxHoldTimeMax = 1440; // 24 hours

  // ── Max Daily Loss (SOL) ──
  static const double maxDailyLossMin = 0.01; // > 0
  static const double maxDailyLossMax = 100.0;

  // ── Cooldown (minutes) ──
  static const int cooldownMin = 0; // ≥ 0
  static const int cooldownMax = 1440;

  // ── Cron/Scan Interval (seconds) ──
  static const int cronIntervalMin = 10;
  static const int cronIntervalMax = 300;

  // ── Min Volume 24h ──
  static const double minVolume24hMin = 0.0; // ≥ 0

  // ── Min Liquidity ──
  static const double minLiquidityMin = 0.0; // ≥ 0

  // ── Max Liquidity ──
  static const double maxLiquidityMin = 1.0; // > 0

  // ── Default Bin Range ──
  static const int binRangeMin = 1;
  static const int binRangeMax = 50;

  // ── Simulation Balance (SOL) ──
  static const double simBalanceMin = 0.1; // > 0
}

/// Form-field validators for bot configuration inputs.
///
/// Each returns `null` on success or an error string on failure.
abstract final class BotValidators {
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length > BotConstraints.nameMaxLength) {
      return 'Max ${BotConstraints.nameMaxLength} characters';
    }
    return null;
  }

  static String? positionSize(String? value) {
    return _validateDouble(
      value,
      label: 'Position size',
      min: BotConstraints.positionSizeMin,
      max: BotConstraints.positionSizeMax,
      unit: 'SOL',
    );
  }

  static String? entryThreshold(String? value) {
    return _validateDouble(
      value,
      label: 'Threshold',
      min: BotConstraints.entryThresholdMin,
      max: BotConstraints.entryThresholdMax,
      unit: '%',
    );
  }

  static String? maxConcurrent(String? value) {
    return _validateInt(
      value,
      label: 'Max concurrent',
      min: BotConstraints.maxConcurrentMin,
      max: BotConstraints.maxConcurrentMax,
    );
  }

  static String? profitTarget(String? value) {
    return _validateDouble(
      value,
      label: 'Profit target',
      min: BotConstraints.profitTargetMin,
      max: BotConstraints.profitTargetMax,
      unit: '%',
    );
  }

  static String? stopLoss(String? value) {
    return _validateDouble(
      value,
      label: 'Stop loss',
      min: BotConstraints.stopLossMin,
      max: BotConstraints.stopLossMax,
      unit: '%',
    );
  }

  static String? maxHoldTime(String? value) {
    return _validateInt(
      value,
      label: 'Hold time',
      min: BotConstraints.maxHoldTimeMin,
      max: BotConstraints.maxHoldTimeMax,
    );
  }

  static String? maxDailyLoss(String? value) {
    return _validateDouble(
      value,
      label: 'Daily loss',
      min: BotConstraints.maxDailyLossMin,
      max: BotConstraints.maxDailyLossMax,
      unit: 'SOL',
    );
  }

  static String? cooldown(String? value) {
    return _validateInt(
      value,
      label: 'Cooldown',
      min: BotConstraints.cooldownMin,
      max: BotConstraints.cooldownMax,
    );
  }

  static String? cronInterval(String? value) {
    return _validateInt(
      value,
      label: 'Interval',
      min: BotConstraints.cronIntervalMin,
      max: BotConstraints.cronIntervalMax,
    );
  }

  // ── Private helpers ──

  static String? _validateDouble(
    String? value, {
    required String label,
    required double min,
    required double max,
    String? unit,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < min) {
      final suffix = unit != null ? ' $unit' : '';
      return 'Min $min$suffix';
    }
    if (parsed > max) {
      final suffix = unit != null ? ' $unit' : '';
      return 'Max $max$suffix';
    }
    return null;
  }

  static String? _validateInt(
    String? value, {
    required String label,
    required int min,
    required int max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a whole number';
    }
    if (parsed < min) {
      return 'Min $min';
    }
    if (parsed > max) {
      return 'Max $max';
    }
    return null;
  }
}

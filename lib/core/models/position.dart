// Position model — maps to backend `/position/*` API responses.
//
// Supports both active (live) and closed (historical) positions.

class Position {
  final String positionId;
  final String? botId;
  final String poolAddress;
  final String? poolName;
  final String status; // "active" or "closed"

  // Pricing
  final double entryPrice;
  final double currentPrice;

  // Timing
  final int entryTimestamp;
  final int? exitTimestamp;
  final double holdTimeMinutes;

  // Amounts
  final double entryAmountYSol;

  // Scoring
  final double entryScore;
  final double? mlProbability;

  // PnL
  final double pnlPercent;
  final double? pnlSol;
  final double? feesEarnedXSol;
  final double? feesEarnedYSol;

  // Exit info (closed positions)
  final String? exitPrice;
  final String? exitReason;

  // Token info (from detailed view)
  final String? tokenXMint;
  final String? tokenYMint;
  final int? binStep;
  final int? entryActiveBinId;
  final double? highWaterMarkPercent;
  final Map<String, dynamic>? entryFeatures;

  // Source tracking
  final String source; // "live" or "db"

  const Position({
    required this.positionId,
    this.botId,
    required this.poolAddress,
    this.poolName,
    required this.status,
    required this.entryPrice,
    required this.currentPrice,
    required this.entryTimestamp,
    this.exitTimestamp,
    required this.holdTimeMinutes,
    required this.entryAmountYSol,
    required this.entryScore,
    this.mlProbability,
    required this.pnlPercent,
    this.pnlSol,
    this.feesEarnedXSol,
    this.feesEarnedYSol,
    this.exitPrice,
    this.exitReason,
    this.tokenXMint,
    this.tokenYMint,
    this.binStep,
    this.entryActiveBinId,
    this.highWaterMarkPercent,
    this.entryFeatures,
    this.source = 'db',
  });

  bool get isActive => status == 'active';
  bool get isLive => source == 'live';
  bool get isProfitable => pnlPercent > 0;

  Duration get holdDuration => Duration(
        milliseconds:
            DateTime.now().millisecondsSinceEpoch - entryTimestamp,
      );

  String get holdDurationFormatted {
    final d = holdDuration;
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  String get displayPnl {
    final prefix = pnlPercent >= 0 ? '+' : '';
    return '$prefix${pnlPercent.toStringAsFixed(2)}%';
  }

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      positionId: json['positionId'] as String,
      botId: json['botId'] as String?,
      poolAddress: json['poolAddress'] as String,
      poolName: json['poolName'] as String?,
      status: json['status'] as String? ?? 'active',
      entryPrice: _parseDouble(json['entryPrice']),
      currentPrice: _parseDouble(json['currentPrice']),
      entryTimestamp: json['entryTimestamp'] as int,
      exitTimestamp: json['exitTimestamp'] as int?,
      holdTimeMinutes: (json['holdTimeMinutes'] as num?)?.toDouble() ?? 0,
      entryAmountYSol: (json['entryAmountYSol'] as num?)?.toDouble() ?? 0,
      entryScore: (json['entryScore'] as num?)?.toDouble() ?? 0,
      mlProbability: (json['mlProbability'] as num?)?.toDouble(),
      pnlPercent: (json['pnlPercent'] as num?)?.toDouble() ?? 0,
      pnlSol: (json['pnlSol'] as num?)?.toDouble(),
      feesEarnedXSol: (json['feesEarnedXSol'] as num?)?.toDouble(),
      feesEarnedYSol: (json['feesEarnedYSol'] as num?)?.toDouble(),
      exitPrice: json['exitPrice']?.toString(),
      exitReason: json['exitReason'] as String?,
      tokenXMint: json['tokenXMint'] as String?,
      tokenYMint: json['tokenYMint'] as String?,
      binStep: json['binStep'] as int?,
      entryActiveBinId: json['entryActiveBinId'] as int?,
      highWaterMarkPercent:
          (json['highWaterMarkPercent'] as num?)?.toDouble(),
      entryFeatures: json['entryFeatures'] as Map<String, dynamic>?,
      source: json['source'] as String? ?? 'db',
    );
  }

  /// Parse entry/current price which may be string or num.
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

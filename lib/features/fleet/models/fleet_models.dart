/// Fleet leaderboard model — one entry per public bot on the platform.
class FleetEntry {
  final int rank;
  final String botId;
  final String name;
  final String owner;
  final String ownerWallet;
  final bool isOwn;
  final String mode;
  final String status;
  final String strategyMode;
  final int totalTrades;
  final int winRate;
  final double pnlSol;
  final double positionSizeSOL;
  final double profitTargetPercent;
  final double stopLossPercent;
  final double entryScoreThreshold;
  final DateTime? lastActivityAt;
  final DateTime createdAt;

  const FleetEntry({
    required this.rank,
    required this.botId,
    required this.name,
    required this.owner,
    required this.ownerWallet,
    required this.isOwn,
    required this.mode,
    required this.status,
    required this.strategyMode,
    required this.totalTrades,
    required this.winRate,
    required this.pnlSol,
    required this.positionSizeSOL,
    required this.profitTargetPercent,
    required this.stopLossPercent,
    required this.entryScoreThreshold,
    this.lastActivityAt,
    required this.createdAt,
  });

  factory FleetEntry.fromJson(Map<String, dynamic> json) {
    return FleetEntry(
      rank: json['rank'] as int,
      botId: json['botId'] as String,
      name: json['name'] as String,
      owner: json['owner'] as String,
      ownerWallet: json['ownerWallet'] as String,
      isOwn: json['isOwn'] as bool? ?? false,
      mode: json['mode'] as String,
      status: json['status'] as String,
      strategyMode: json['strategyMode'] as String,
      totalTrades: json['totalTrades'] as int,
      winRate: json['winRate'] as int,
      pnlSol: (json['pnlSol'] as num).toDouble(),
      positionSizeSOL: (json['positionSizeSOL'] as num).toDouble(),
      profitTargetPercent: (json['profitTargetPercent'] as num).toDouble(),
      stopLossPercent: (json['stopLossPercent'] as num).toDouble(),
      entryScoreThreshold: (json['entryScoreThreshold'] as num).toDouble(),
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isRunning => status == 'running';
  bool get isProfitable => pnlSol > 0;
}

class FleetStats {
  final int totalBots;
  final int publicBots;
  final int runningBots;
  final int totalTrades;
  final double totalPnlSol;
  final int avgWinRatePercent;

  const FleetStats({
    required this.totalBots,
    required this.publicBots,
    required this.runningBots,
    required this.totalTrades,
    required this.totalPnlSol,
    required this.avgWinRatePercent,
  });

  factory FleetStats.fromJson(Map<String, dynamic> json) {
    return FleetStats(
      totalBots: json['totalBots'] as int,
      publicBots: json['publicBots'] as int,
      runningBots: json['runningBots'] as int,
      totalTrades: json['totalTrades'] as int,
      totalPnlSol: (json['totalPnlSol'] as num).toDouble(),
      avgWinRatePercent: json['avgWinRatePercent'] as int,
    );
  }
}

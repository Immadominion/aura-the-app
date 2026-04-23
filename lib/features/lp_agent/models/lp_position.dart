/// LP Agent canonical position model.
///
/// Mirrors the response shape from `GET /lp-agent/positions/opening`.
/// Represents a position that the LP Agent service is tracking on behalf
/// of the wallet — shown in the mobile UI under the "External" section
/// of the Positions tab.
library;

class LpPosition {
  /// LP Agent's internal position id (used for decrease/close ops).
  final String id;

  /// Pool address.
  final String poolAddress;

  final String token0Symbol;
  final String token1Symbol;

  /// Owner wallet (must match the authenticated user).
  final String owner;

  /// Position open timestamp (ms since epoch). Null if the upstream
  /// payload omits it.
  final int? openedAt;

  /// Current value in USD (or whatever quote unit the upstream returns).
  final double currentValue;

  /// Unrealised PnL in USD.
  final double pnl;

  /// Raw upstream payload — kept around so detail screens can show
  /// any field without a model change.
  final Map<String, dynamic> raw;

  const LpPosition({
    required this.id,
    required this.poolAddress,
    required this.token0Symbol,
    required this.token1Symbol,
    required this.owner,
    required this.openedAt,
    required this.currentValue,
    required this.pnl,
    required this.raw,
  });

  static LpPosition? fromJson(Map<String, dynamic> row) {
    final id = (row['id'] as String?) ?? (row['position_id'] as String?);
    final pool = (row['pool'] as String?) ?? (row['pool_address'] as String?);
    if (id == null || id.isEmpty || pool == null || pool.isEmpty) return null;

    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
    int? asIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse('$v');
    }

    return LpPosition(
      id: id,
      poolAddress: pool,
      token0Symbol: '${row['token0_symbol'] ?? 'TOKEN0'}',
      token1Symbol: '${row['token1_symbol'] ?? 'TOKEN1'}',
      owner: '${row['owner'] ?? ''}',
      openedAt: asIntOrNull(row['opened_at'] ?? row['created_at']),
      currentValue: asDouble(row['current_value'] ?? row['value']),
      pnl: asDouble(row['pnl'] ?? row['unrealized_pnl']),
      raw: row,
    );
  }
}

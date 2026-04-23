/// LP Agent canonical pool model.
///
/// Mirrors the response shape from the Aura backend's
/// `GET /lp-agent/pools/discover` proxy (which itself wraps
/// api.lpagent.io). Field naming follows the upstream snake_case payload
/// so the repository's mapping stays trivial to audit against
/// `aura-backend/src/services/lp-agent.ts`.
library;

class LpPool {
  /// Pool address (Solana base58 pubkey).
  final String address;

  final String token0Symbol;
  final String token1Symbol;
  final String token0Mint;
  final String token1Mint;

  /// DLMM bin step in basis points.
  final int binStep;

  /// Base fee percentage (e.g. `0.01` for 1bp).
  final double feePct;

  /// Total value locked, USD.
  final double tvlUsd;

  /// Trailing volumes, USD.
  final double volume1hUsd;
  final double volume24hUsd;

  /// Current quoted price (token1 per token0).
  final double price;

  /// Raw upstream row, retained for forward-compat / debug.
  final Map<String, dynamic> raw;

  const LpPool({
    required this.address,
    required this.token0Symbol,
    required this.token1Symbol,
    required this.token0Mint,
    required this.token1Mint,
    required this.binStep,
    required this.feePct,
    required this.tvlUsd,
    required this.volume1hUsd,
    required this.volume24hUsd,
    required this.price,
    required this.raw,
  });

  /// Display label, e.g. `"SOL / USDC"`.
  String get pairName => '$token0Symbol / $token1Symbol';

  /// 24h fee earnings estimate (USD), using the simple `vol * fee%`
  /// model the backend's MarketDataProvider also applies for ranking.
  double get fees24hUsd => volume24hUsd * (feePct / 100);

  /// Volume-to-liquidity ratio — proxy for capital efficiency.
  double get volumeToLiquidity => tvlUsd > 0 ? volume24hUsd / tvlUsd : 0;

  /// Decode a single discoverPools row. Returns `null` when the row is
  /// missing a pool address (defensive — never trust upstream shape).
  static LpPool? fromJson(Map<String, dynamic> json) {
    final address = (json['pool'] ?? '').toString().trim();
    if (address.isEmpty) return null;

    double num0(Object? v) => switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0.0,
      _ => 0.0,
    };
    int int0(Object? v) => switch (v) {
      num n => n.toInt(),
      String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

    return LpPool(
      address: address,
      token0Symbol: (json['token0_symbol'] ?? 'TOKEN0').toString(),
      token1Symbol: (json['token1_symbol'] ?? 'TOKEN1').toString(),
      token0Mint: (json['token0'] ?? '').toString(),
      token1Mint: (json['token1'] ?? '').toString(),
      binStep: int0(json['bin_step'] ?? 1),
      feePct: num0(json['fee']),
      tvlUsd: num0(json['tvl']),
      volume1hUsd: num0(json['vol_1h']),
      volume24hUsd: num0(json['vol_24h']),
      price: num0(json['quote_price'] ?? json['base_price']),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

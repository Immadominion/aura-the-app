/// Seal smart wallet on-chain state.
class WalletState {
  final String address;
  final String owner;
  final double dailyLimitSOL;
  final double perTxLimitSOL;
  final double spentTodaySOL;
  final String nonce;
  final bool isLocked;
  final bool exists;
  final List<String> guardians;

  const WalletState({
    required this.address,
    required this.owner,
    required this.dailyLimitSOL,
    required this.perTxLimitSOL,
    required this.spentTodaySOL,
    required this.nonce,
    required this.isLocked,
    this.exists = true,
    this.guardians = const [],
  });

  double get remainingTodaySOL => dailyLimitSOL - spentTodaySOL;

  factory WalletState.fromJson(Map<String, dynamic> json) {
    final exists = json['exists'] as bool? ?? false;
    if (!exists) {
      return WalletState(
        address: json['walletAddress'] as String? ?? '',
        owner: '',
        dailyLimitSOL: 0,
        perTxLimitSOL: 0,
        spentTodaySOL: 0,
        nonce: '0',
        isLocked: false,
        exists: false,
      );
    }
    final wallet = json['wallet'] as Map<String, dynamic>? ?? json;
    return WalletState(
      address: wallet['address'] as String? ?? '',
      owner: wallet['owner'] as String? ?? '',
      dailyLimitSOL: (wallet['dailyLimitSol'] as num?)?.toDouble() ?? 0,
      perTxLimitSOL: (wallet['perTxLimitSol'] as num?)?.toDouble() ?? 0,
      spentTodaySOL: (wallet['spentTodaySol'] as num?)?.toDouble() ?? 0,
      nonce: wallet['nonce']?.toString() ?? '0',
      isLocked: wallet['isLocked'] as bool? ?? false,
      exists: true,
      guardians:
          (wallet['guardians'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// Balance response from /wallet/balance.
class WalletBalance {
  final double balanceSOL;
  final int balanceLamports;

  const WalletBalance({
    required this.balanceSOL,
    required this.balanceLamports,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) => WalletBalance(
    balanceSOL: (json['sol'] as num?)?.toDouble() ?? 0,
    balanceLamports: json['lamports'] as int? ?? 0,
  );
}

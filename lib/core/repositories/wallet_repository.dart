import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wallet.dart';
import '../services/api_client.dart';

/// Repository for Seal smart wallet operations.
class WalletRepository {
  final ApiClient _api;

  WalletRepository(this._api);

  /// Prepare a transaction for Seal wallet creation.
  /// When sponsor is configured server-side, the TX is partially signed
  /// (user pays nothing for rent). Otherwise, user pays.
  ///
  /// Returns `{ transaction, walletAddress, sponsored, blockhash, ... }`.
  Future<Map<String, dynamic>> prepareCreate({
    double dailyLimitSol = 10,
    double perTxLimitSol = 1,
  }) async {
    final response = await _api.post(
      '/wallet/prepare-create',
      data: {'dailyLimitSol': dailyLimitSol, 'perTxLimitSol': perTxLimitSol},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get on-chain Seal wallet state.
  Future<WalletState> getWalletState() async {
    final response = await _api.get('/wallet/state');
    return WalletState.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get Seal wallet SOL balance.
  Future<WalletBalance> getBalance() async {
    final response = await _api.get('/wallet/balance');
    return WalletBalance.fromJson(response.data as Map<String, dynamic>);
  }

  /// Prepare an unsigned TX that creates a Seal wallet AND deposits
  /// SOL into it — the user signs once via MWA.
  ///
  /// Returns `{ transaction, walletAddress, depositSol, blockhash, ... }`.
  Future<Map<String, dynamic>> prepareCreateAndFund({
    required double depositSol,
    double dailyLimitSol = 10,
    double perTxLimitSol = 1,
  }) async {
    final response = await _api.post(
      '/wallet/prepare-create-and-fund',
      data: {
        'depositSol': depositSol,
        'dailyLimitSol': dailyLimitSol,
        'perTxLimitSol': perTxLimitSol,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Check if sponsored wallet creation is available.
  /// When true, the user doesn't pay gas/rent for wallet creation.
  Future<bool> isSponsorAvailable() async {
    try {
      final response = await _api.get('/wallet/sponsor-status');
      final data = response.data as Map<String, dynamic>;
      return data['sponsored'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Prepare an unsigned TX that transfers additional SOL into an
  /// existing Seal wallet.
  Future<Map<String, dynamic>> prepareDeposit({
    required double amountSol,
  }) async {
    final response = await _api.post(
      '/wallet/prepare-deposit',
      data: {'amountSol': amountSol},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Prepare an owner-signed recovery transaction that closes the on-chain
  /// wallet and returns all SOL back to the connected wallet.
  Future<Map<String, dynamic>> prepareRecoverWallet() async {
    final response = await _api.post(
      '/wallet/prepare-recover-wallet',
      data: {},
    );
    return response.data as Map<String, dynamic>;
  }

  // ═══════════════════════════════════════════════════════════════
  // Per-Bot Agent & Session Key Operations
  // ═══════════════════════════════════════════════════════════════

  /// Prepare TX to register a bot as a Seal agent.
  ///
  /// [botId] — 8-char hex bot identifier.
  /// [agentPubkey] — base58 public key of the agent keypair (generated client-side).
  ///
  /// Returns `{ transaction, agentPubkey, agentConfigAddress, sponsored, ... }`.
  Future<Map<String, dynamic>> prepareRegisterAgent({
    required String botId,
    required String agentPubkey,
    String name = 'Sage Bot Agent',
    double dailyLimitSol = 5,
    double perTxLimitSol = 1,
  }) async {
    final response = await _api.post(
      '/wallet/prepare-register-agent',
      data: {
        'botId': botId,
        'agentPubkey': agentPubkey,
        'name': name,
        'dailyLimitSol': dailyLimitSol,
        'perTxLimitSol': perTxLimitSol,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Prepare TX to create a session key for a bot's agent.
  ///
  /// The session key is an ephemeral keypair that allows the bot to
  /// execute transactions autonomously within spending limits.
  ///
  /// [botId] — 8-char hex bot identifier (must have a registered agent).
  /// [sessionPubkey] — base58 public key of the ephemeral session keypair.
  ///
  /// Returns `{ transaction, sessionAddress, sessionPubkey, ... }`.
  Future<Map<String, dynamic>> prepareCreateSession({
    required String botId,
    required String sessionPubkey,
    int durationSecs = 24 * 60 * 60,
    double maxAmountSol = 5,
    double maxPerTxSol = 1,
  }) async {
    final response = await _api.post(
      '/wallet/prepare-create-session',
      data: {
        'botId': botId,
        'sessionPubkey': sessionPubkey,
        'durationSecs': durationSecs,
        'maxAmountSol': maxAmountSol,
        'maxPerTxSol': maxPerTxSol,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Prepare TX to revoke an active session key for a bot.
  ///
  /// Either the wallet owner or the agent can revoke a session.
  /// This prepares the TX for the owner to sign via MWA.
  ///
  /// Returns `{ transaction, sessionAddress, ... }` or
  /// `{ alreadyRevoked: true }` / `{ alreadyClosed: true }` if
  /// the session was already revoked or closed on-chain.
  Future<Map<String, dynamic>> prepareRevokeSession({
    required String botId,
  }) async {
    final response = await _api.post(
      '/wallet/prepare-revoke-session',
      data: {'botId': botId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// One-shot live mode setup: server generates agent + session keypairs,
  /// builds RegisterAgent + CreateSession in a single TX (partially signed
  /// by the generated agent key). The caller must sign with MWA (owner).
  ///
  /// Returns `{ transaction, agentPubkey, sessionAddress, sessionPubkey,
  ///   sponsored, blockhash, lastValidBlockHeight, ... }`.
  Future<Map<String, dynamic>> setupLive({
    required String botId,
    double dailyLimitSol = 10,
    double perTxLimitSol = 2,
    int sessionDurationSecs = 7 * 24 * 60 * 60,
    double sessionMaxAmountSol = 100,
    double sessionMaxPerTxSol = 2,
  }) async {
    final response = await _api.post(
      '/wallet/setup-live',
      data: {
        'botId': botId,
        'dailyLimitSol': dailyLimitSol,
        'perTxLimitSol': perTxLimitSol,
        'sessionDurationSecs': sessionDurationSecs,
        'sessionMaxAmountSol': sessionMaxAmountSol,
        'sessionMaxPerTxSol': sessionMaxPerTxSol,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Submit a fully-signed transaction to the Solana network via backend.
  ///
  /// Used after MWA signs the transaction. The app uses
  /// `signTransactions` (sign-only) and the backend submits it.
  ///
  /// Returns `{ success, signature }`.
  Future<Map<String, dynamic>> submitSigned({
    required String transactionBase64,
    String? setupLiveBotId,
    bool recoverWalletClose = false,
  }) async {
    final response = await _api.post(
      '/wallet/submit-signed',
      data: {
        'transaction': transactionBase64,
        if (setupLiveBotId != null) 'setupLiveBotId': setupLiveBotId,
        if (recoverWalletClose) 'recoverWalletClose': true,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // NOTE: Direct withdrawal via SystemProgram.transfer is impossible
  // because the Seal wallet PDA is owned by the Seal program, not
  // SystemProgram. Use prepareRecoverWallet() + submitSigned() instead,
  // which closes the wallet on-chain and returns all SOL to the owner.
}

/// WalletRepository Riverpod provider.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.read(apiClientProvider));
});

/// Wallet balance provider (auto-refresh).
final walletBalanceProvider = FutureProvider<WalletBalance>((ref) async {
  final repo = ref.read(walletRepositoryProvider);
  return repo.getBalance();
});

/// Wallet state provider.
final walletStateProvider = FutureProvider<WalletState>((ref) async {
  final repo = ref.read(walletRepositoryProvider);
  return repo.getWalletState();
});

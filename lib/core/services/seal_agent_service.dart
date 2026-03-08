import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solana/solana.dart'
    show Commitment, Ed25519HDKeyPair, RpcClient;
import 'package:bs58/bs58.dart';

import 'package:sage/core/config/env_config.dart';
import 'package:sage/core/repositories/wallet_repository.dart';
import 'package:sage/core/services/mwa_wallet_service.dart';

/// Result of an agent registration or session creation flow.
class SealTxResult {
  final bool success;
  final String? txSignature;
  final String? error;
  final Map<String, dynamic>? data;

  const SealTxResult._({
    required this.success,
    this.txSignature,
    this.error,
    this.data,
  });

  factory SealTxResult.ok({String? txSignature, Map<String, dynamic>? data}) =>
      SealTxResult._(success: true, txSignature: txSignature, data: data);

  factory SealTxResult.fail(String error) =>
      SealTxResult._(success: false, error: error);
}

/// Manages Seal agent keypairs and session key lifecycle.
///
/// Handles:
/// - Agent keypair generation + secure storage
/// - Agent registration via MWA (owner signs)
/// - Session keypair generation + secure storage
/// - Session creation via local signing (agent signs)
/// - Session revocation via MWA (owner signs)
///
/// All private keys are stored in [FlutterSecureStorage], keyed by bot ID.
class SealAgentService {
  final WalletRepository _walletRepo;
  final MwaWalletService _mwa;
  final FlutterSecureStorage _storage;
  late final RpcClient _rpc;

  SealAgentService({
    required WalletRepository walletRepo,
    required MwaWalletService mwa,
    FlutterSecureStorage? storage,
  }) : _walletRepo = walletRepo,
       _mwa = mwa,
       _storage = storage ?? const FlutterSecureStorage() {
    _rpc = RpcClient(EnvConfig.solanaRpcUrl);
  }

  // ═══════════════════════════════════════════════════════════════
  // Storage Keys
  // ═══════════════════════════════════════════════════════════════

  /// Secure storage key for the agent private key (64-byte Ed25519 seed+pubkey).
  String _agentKeyStorageKey(String botId) => 'seal_agent_$botId';

  /// Secure storage key for the session private key.
  String _sessionKeyStorageKey(String botId) => 'seal_session_$botId';

  // ═══════════════════════════════════════════════════════════════
  // Keypair Management
  // ═══════════════════════════════════════════════════════════════

  /// Generate a fresh Ed25519 keypair and store the private key securely.
  ///
  /// Returns the [Ed25519HDKeyPair] instance.
  Future<Ed25519HDKeyPair> _generateAndStoreKeypair(String storageKey) async {
    final keypair = await Ed25519HDKeyPair.random();

    // Extract the raw private key (32-byte seed) + public key.
    final data = await keypair.extract();
    final privateKeyBytes = data.bytes;
    final publicKeyBytes = keypair.publicKey.bytes;

    // Store as base64: [32-byte seed | 32-byte pubkey]
    final fullKey = Uint8List(64);
    fullKey.setRange(0, 32, privateKeyBytes);
    fullKey.setRange(32, 64, publicKeyBytes);

    await _storage.write(key: storageKey, value: base64Encode(fullKey));

    return keypair;
  }

  /// Load a previously stored keypair from secure storage.
  ///
  /// Returns null if no keypair exists for this key.
  Future<Ed25519HDKeyPair?> _loadKeypair(String storageKey) async {
    final stored = await _storage.read(key: storageKey);
    if (stored == null) return null;

    try {
      final bytes = base64Decode(stored);
      if (bytes.length != 64) return null;

      // Reconstruct from the 32-byte seed (first half)
      final seed = bytes.sublist(0, 32);
      return await Ed25519HDKeyPair.fromSeedWithHdPath(
        seed: seed,
        hdPath: "m/44'/501'/0'/0'",
      );
    } catch (e) {
      debugPrint('[SealAgent] Failed to load keypair: $e');
      return null;
    }
  }

  /// Check if an agent keypair exists for a bot.
  Future<bool> hasAgentKeypair(String botId) async {
    final stored = await _storage.read(key: _agentKeyStorageKey(botId));
    return stored != null;
  }

  /// Get the stored agent public key for a bot, if available.
  Future<String?> getAgentPublicKey(String botId) async {
    final stored = await _storage.read(key: _agentKeyStorageKey(botId));
    if (stored == null) return null;

    try {
      final bytes = base64Decode(stored);
      if (bytes.length != 64) return null;
      // Public key is the last 32 bytes
      return base58.encode(Uint8List.fromList(bytes.sublist(32, 64)));
    } catch (_) {
      return null;
    }
  }

  /// Delete all stored keys for a bot (cleanup on bot deletion).
  Future<void> deleteKeysForBot(String botId) async {
    await _storage.delete(key: _agentKeyStorageKey(botId));
    await _storage.delete(key: _sessionKeyStorageKey(botId));
  }

  // ═══════════════════════════════════════════════════════════════
  // Agent Registration (Owner signs via MWA)
  // ═══════════════════════════════════════════════════════════════

  /// Register a bot as a Seal agent.
  ///
  /// 1. Generates a fresh agent keypair and stores it securely
  /// 2. Calls backend to prepare the RegisterAgent TX
  /// 3. Signs via MWA (wallet owner is the signer)
  /// 4. Returns the TX signature
  Future<SealTxResult> registerAgent({
    required String botId,
    String name = 'Sage Bot Agent',
    double dailyLimitSol = 5,
    double perTxLimitSol = 1,
  }) async {
    try {
      // Step 1: Generate agent keypair
      final agentKeypair = await _generateAndStoreKeypair(
        _agentKeyStorageKey(botId),
      );
      final agentPubkey = agentKeypair.publicKey.toBase58();

      debugPrint('[SealAgent] Generated agent pubkey: $agentPubkey');

      // Step 2: Prepare TX via backend
      final txData = await _walletRepo.prepareRegisterAgent(
        botId: botId,
        agentPubkey: agentPubkey,
        name: name,
        dailyLimitSol: dailyLimitSol,
        perTxLimitSol: perTxLimitSol,
      );

      final txBase64 = txData['transaction'] as String;
      final network = txData['network'] as String? ?? 'mainnet-beta';
      final txBytes = Uint8List.fromList(base64Decode(txBase64));

      // Step 3: Sign via MWA (owner is the signer for RegisterAgent)
      final signatures = await _mwa.signAndSendTransactions([
        txBytes,
      ], cluster: network);

      if (signatures.isEmpty) {
        // User cancelled — clean up the stored keypair
        await _storage.delete(key: _agentKeyStorageKey(botId));
        return SealTxResult.fail('Transaction was rejected by wallet');
      }

      return SealTxResult.ok(
        txSignature: signatures.first,
        data: {
          'agentPubkey': agentPubkey,
          'agentConfigAddress': txData['agentConfigAddress'],
        },
      );
    } catch (e) {
      // Clean up on failure
      await _storage.delete(key: _agentKeyStorageKey(botId));
      return SealTxResult.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Session Creation (Agent signs locally)
  // ═══════════════════════════════════════════════════════════════

  /// Create a session key for a bot's agent.
  ///
  /// 1. Loads the stored agent keypair
  /// 2. Generates a fresh session keypair
  /// 3. Calls backend to prepare the CreateSession TX
  /// 4. Signs locally with the agent keypair (agent is the signer/payer)
  /// 5. Sends to Solana directly (bypasses MWA)
  Future<SealTxResult> createSession({
    required String botId,
    int durationSecs = 24 * 60 * 60,
    double maxAmountSol = 5,
    double maxPerTxSol = 1,
  }) async {
    try {
      // Step 1: Load agent keypair
      final agentKeypair = await _loadKeypair(_agentKeyStorageKey(botId));
      if (agentKeypair == null) {
        return SealTxResult.fail(
          'Wallet keypair not found. Complete the live setup first.',
        );
      }

      // Step 2: Generate session keypair
      final sessionKeypair = await _generateAndStoreKeypair(
        _sessionKeyStorageKey(botId),
      );
      final sessionPubkey = sessionKeypair.publicKey.toBase58();

      debugPrint('[SealAgent] Generated session pubkey: $sessionPubkey');

      // Step 3: Prepare TX via backend
      final txData = await _walletRepo.prepareCreateSession(
        botId: botId,
        sessionPubkey: sessionPubkey,
        durationSecs: durationSecs,
        maxAmountSol: maxAmountSol,
        maxPerTxSol: maxPerTxSol,
      );

      final txBase64 = txData['transaction'] as String;

      // Step 4: Sign locally with agent keypair
      // The TX has agent as feePayer. We deserialize, sign, and send.
      final signedTx = await _signTransactionLocally(
        txBase64: txBase64,
        signer: agentKeypair,
      );

      // Step 5: Send to Solana directly
      final txSignature = await _rpc.sendTransaction(
        signedTx,
        preflightCommitment: Commitment.confirmed,
        skipPreflight: false,
      );

      return SealTxResult.ok(
        txSignature: txSignature,
        data: {
          'sessionAddress': txData['sessionAddress'],
          'sessionPubkey': sessionPubkey,
        },
      );
    } catch (e) {
      await _storage.delete(key: _sessionKeyStorageKey(botId));
      return SealTxResult.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Session Revocation (Owner signs via MWA)
  // ═══════════════════════════════════════════════════════════════

  /// Revoke an active session key for a bot.
  ///
  /// 1. Calls backend to prepare the RevokeSession TX
  /// 2. Signs via MWA (wallet owner is the signer)
  /// 3. Cleans up stored session keypair
  Future<SealTxResult> revokeSession({required String botId}) async {
    try {
      final txData = await _walletRepo.prepareRevokeSession(botId: botId);

      // If session was already revoked/closed on-chain, no TX needed
      if (txData['alreadyRevoked'] == true || txData['alreadyClosed'] == true) {
        await _storage.delete(key: _sessionKeyStorageKey(botId));
        return SealTxResult.ok(data: {'message': txData['message']});
      }

      final txBase64 = txData['transaction'] as String;
      final network = txData['network'] as String? ?? 'mainnet-beta';
      final txBytes = Uint8List.fromList(base64Decode(txBase64));

      // Sign via MWA (owner is the authority for revocation)
      final signatures = await _mwa.signAndSendTransactions([
        txBytes,
      ], cluster: network);

      if (signatures.isEmpty) {
        return SealTxResult.fail('Transaction was rejected by wallet');
      }

      // Clean up stored session keypair
      await _storage.delete(key: _sessionKeyStorageKey(botId));

      return SealTxResult.ok(
        txSignature: signatures.first,
        data: {'sessionAddress': txData['sessionAddress']},
      );
    } catch (e) {
      return SealTxResult.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Internal: Local Transaction Signing
  // ═══════════════════════════════════════════════════════════════

  /// Deserialize an unsigned TX, sign with a local keypair, and return
  /// the base64-encoded signed transaction ready for RPC submission.
  Future<String> _signTransactionLocally({
    required String txBase64,
    required Ed25519HDKeyPair signer,
  }) async {
    final txBytes = base64Decode(txBase64);

    // A Solana transaction wire format:
    //   [compact-u16 sig count] [64-byte signatures...] [message bytes]
    //
    // The backend serializes with requireAllSignatures: false,
    // so there's one empty 64-byte signature slot for the agent.
    //
    // We need to:
    // 1. Extract the message bytes (everything after the signature slots)
    // 2. Sign the message bytes with our keypair
    // 3. Insert the signature into the slot
    // 4. Return the fully signed transaction

    final buffer = Uint8List.fromList(txBytes);
    final sigCount = buffer[0]; // compact-u16 for small values (< 128)
    final sigOffset = 1; // After the compact-u16 byte
    final messageOffset = sigOffset + (sigCount * 64);
    final messageBytes = buffer.sublist(messageOffset);

    // Sign the message
    final signature = await signer.sign(messageBytes);
    final sigBytes = signature.bytes;

    if (sigBytes.length != 64) {
      throw Exception('Invalid signature length: ${sigBytes.length}');
    }

    // Insert signature into the first slot
    // (the agent is listed first in the keys/signers array)
    buffer.setRange(sigOffset, sigOffset + 64, sigBytes);

    return base64Encode(buffer);
  }
}

// ═══════════════════════════════════════════════════════════════
// Riverpod Provider
// ═══════════════════════════════════════════════════════════════

final sealAgentServiceProvider = Provider<SealAgentService>((ref) {
  return SealAgentService(
    walletRepo: ref.read(walletRepositoryProvider),
    mwa: ref.read(mwaWalletServiceProvider),
  );
});

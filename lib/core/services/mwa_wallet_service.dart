import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solana_mobile_client/solana_mobile_client.dart';

// ── Minimal base58 encoder (Bitcoin alphabet) ──
const _alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

String _base58encode(Uint8List bytes) {
  if (bytes.isEmpty) return '';
  // Count leading zeros.
  var zeros = 0;
  while (zeros < bytes.length && bytes[zeros] == 0) {
    zeros++;
  }
  // Convert to big-endian base58.
  final encoded = <int>[];
  var start = zeros;
  while (start < bytes.length) {
    var carry = 0;
    for (var i = start; i < bytes.length; i++) {
      carry = carry * 256 + bytes[i];
      bytes[i] = carry ~/ 58;
      carry = carry % 58;
    }
    encoded.add(carry);
    while (start < bytes.length && bytes[start] == 0) {
      start++;
    }
  }
  final buf = StringBuffer();
  for (var i = 0; i < zeros; i++) {
    buf.write('1');
  }
  for (var i = encoded.length - 1; i >= 0; i--) {
    buf.write(_alphabet[encoded[i]]);
  }
  return buf.toString();
}

// ─────────────────────────────────────────────────────────
// MWA Wallet Service — Aura
//
// Single entry point for wallet operations via Solana
// Mobile Wallet Adapter. Android-only (Seeker target).
// Auto-discovers whatever wallet app is installed.
// ─────────────────────────────────────────────────────────

/// MWA identity URI shown in wallet approval dialogs.
final _identityUri = Uri.parse('https://useaura.wtf');

/// Result of an MWA wallet connection attempt.
class MwaConnectionResult {
  final bool success;
  final String? publicKey;
  final String? authToken;
  final String? walletName;
  final String? error;

  const MwaConnectionResult._({
    required this.success,
    this.publicKey,
    this.authToken,
    this.walletName,
    this.error,
  });

  factory MwaConnectionResult.ok({
    required String publicKey,
    required String authToken,
    String? walletName,
  }) => MwaConnectionResult._(
    success: true,
    publicKey: publicKey,
    authToken: authToken,
    walletName: walletName,
  );

  factory MwaConnectionResult.fail(String error) =>
      MwaConnectionResult._(success: false, error: error);
}

/// Result of the combined SIWS flow (single MWA session).
class SiwsResult {
  final String publicKey;
  final Uint8List signature;
  final String authToken;
  final String? walletName;

  const SiwsResult({
    required this.publicKey,
    required this.signature,
    required this.authToken,
    this.walletName,
  });
}

/// Lightweight MWA service for Aura.
///
/// Handles connect / disconnect. Sign operations will be
/// added when the trading engine is wired up.
class MwaWalletService {
  String? _publicKey;
  String? _authToken;
  String _authCluster = 'mainnet-beta';
  final FlutterSecureStorage _storage;

  MwaWalletService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Currently connected wallet address (base58), or null.
  String? get publicKey => _publicKey;

  /// Stored auth token for reauthorize flows (signing).
  String? get authToken => _authToken;

  /// Whether MWA is available (Android only).
  bool get isAvailable => Platform.isAndroid;

  /// Set auth token externally (e.g. synced from SiwsService after sign-in).
  Future<void> setAuthToken(String token, {String? publicKey}) async {
    _authToken = token;
    if (publicKey != null) _publicKey = publicKey;
    await _storage.write(key: 'mwa_auth_token', value: token);
    if (publicKey != null) {
      await _storage.write(key: 'mwa_public_key', value: publicKey);
    }
    debugPrint(
      '[MWA] Auth token set${publicKey != null ? ' for $publicKey' : ''}',
    );
  }

  /// Load persisted MWA auth token from secure storage.
  Future<void> loadAuthToken() async {
    _authToken = await _storage.read(key: 'mwa_auth_token');
    _publicKey = await _storage.read(key: 'mwa_public_key');
    _authCluster =
        await _storage.read(key: 'mwa_auth_cluster') ?? 'mainnet-beta';
    if (_authToken != null) {
      debugPrint(
        '[MWA] Loaded persisted auth token for $_publicKey (cluster=$_authCluster)',
      );
    }
  }

  /// Connect to an installed wallet via MWA.
  ///
  /// Launches the system wallet chooser for any installed
  /// MWA-compatible Solana wallet on the device.
  Future<MwaConnectionResult> connect() async {
    if (!isAvailable) {
      return MwaConnectionResult.fail('MWA is only available on Android');
    }

    try {
      final session = await LocalAssociationScenario.create();

      // Fire-and-forget: opens the wallet app picker.
      session.startActivityForResult(null).ignore();

      final client = await session.start();

      final auth = await client.authorize(
        identityUri: _identityUri,
        identityName: 'Aura',
        iconUri: Uri.parse('logo.png'),
        cluster: 'mainnet-beta',
      );

      if (auth == null) {
        await session.close();
        return MwaConnectionResult.fail('Authorization cancelled');
      }

      final pk = _base58encode(Uint8List.fromList(auth.publicKey));

      _publicKey = pk;
      _authToken = auth.authToken;

      await session.close();

      return MwaConnectionResult.ok(
        publicKey: pk,
        authToken: auth.authToken,
        walletName: auth.accountLabel,
      );
    } catch (e) {
      return MwaConnectionResult.fail(e.toString());
    }
  }

  /// Single-session SIWS flow: authorize + sign in one wallet interaction.
  ///
  /// Opens the wallet app ONCE. After authorization, calls [getMessageToSign]
  /// with the wallet address to fetch the SIWS nonce, then signs it — all
  /// within the same MWA session. This avoids the double-open bug where
  /// the wallet app launches twice (and the second time fails to return).
  Future<SiwsResult> connectAndSign({
    required Future<Uint8List> Function(String walletAddress) getMessageToSign,
  }) async {
    if (!isAvailable) {
      throw MwaException('MWA is only available on Android');
    }

    final session = await LocalAssociationScenario.create();
    try {
      session.startActivityForResult(null).ignore();
      final client = await session.start();

      // Step 1: Authorize — wallet shows approval prompt.
      final auth = await client.authorize(
        identityUri: _identityUri,
        identityName: 'Aura',
        iconUri: Uri.parse('logo.png'),
        cluster: 'mainnet-beta',
      );

      if (auth == null) {
        throw MwaException('Authorization cancelled');
      }

      final pk = _base58encode(Uint8List.fromList(auth.publicKey));

      // Step 2: Fetch the SIWS message to sign (HTTP to backend).
      // The wallet app stays in foreground while this happens.
      final messageBytes = await getMessageToSign(pk);

      // Step 3: Sign the nonce message — wallet shows sign prompt.
      final result = await client.signMessages(
        messages: [messageBytes],
        addresses: [Uint8List.fromList(auth.publicKey)],
      );

      if (result.signedMessages.isEmpty ||
          result.signedMessages.first.signatures.isEmpty) {
        throw MwaException('Signing failed — no signature returned');
      }

      final signature = Uint8List.fromList(
        result.signedMessages.first.signatures.first,
      );

      _publicKey = pk;
      _authToken = auth.authToken;

      return SiwsResult(
        publicKey: pk,
        signature: signature,
        authToken: auth.authToken,
        walletName: auth.accountLabel,
      );
    } finally {
      await session.close();
    }
  }

  /// Sign a message (for SIWS authentication).
  ///
  /// Opens MWA session, reauthorizes with stored auth token,
  /// and signs the provided message bytes.
  /// Returns the signature bytes, or null if signing failed/cancelled.
  ///
  /// **Prefer [connectAndSign] for the SIWS login flow** — it avoids
  /// opening the wallet app twice.
  Future<Uint8List?> signMessage(Uint8List message) async {
    if (!isAvailable || _authToken == null) return null;

    try {
      final session = await LocalAssociationScenario.create();
      session.startActivityForResult(null).ignore();
      final client = await session.start();

      // Reauthorize using stored auth token.
      final reauth = await client.reauthorize(
        identityUri: _identityUri,
        identityName: 'Aura',
        iconUri: Uri.parse('logo.png'),
        authToken: _authToken!,
      );

      if (reauth == null) {
        await session.close();
        return null;
      }

      _authToken = reauth.authToken;

      // Sign the message.
      final result = await client.signMessages(
        messages: [message],
        addresses: [Uint8List.fromList(reauth.publicKey)],
      );

      await session.close();

      if (result.signedMessages.isNotEmpty &&
          result.signedMessages.first.signatures.isNotEmpty) {
        // Extract the 64-byte Ed25519 signature from the first signed message.
        return Uint8List.fromList(result.signedMessages.first.signatures.first);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Sign and send serialized transactions via MWA.
  ///
  /// Opens a single MWA session. If a stored auth token exists, tries
  /// `reauthorize` for a seamless experience. Falls back to full
  /// `authorize` (shows wallet approval prompt) when no token is
  /// available or reauthorize fails — e.g. after a hot-reload.
  ///
  /// Returns the list of base58 transaction signatures.
  ///
  /// [cluster] defaults to `'mainnet-beta'`. Pass `'devnet'` when
  /// transacting against devnet programs.
  Future<List<String>> signAndSendTransactions(
    List<Uint8List> transactions, {
    String cluster = 'mainnet-beta',
  }) async {
    if (!isAvailable) {
      throw MwaException('MWA is only available on Android');
    }

    final session = await LocalAssociationScenario.create();
    try {
      session.startActivityForResult(null).ignore();
      final client = await session.start();

      // Try reauthorize with stored token; fall back to full authorize.
      // IMPORTANT: reauthorize inherits the cluster from the original
      // authorize call. If the requested cluster differs we MUST do a
      // fresh authorize so the wallet sends the TX to the right network.
      String? sessionAuthToken;

      if (_authToken != null && cluster == _authCluster) {
        try {
          final reauth = await client.reauthorize(
            identityUri: _identityUri,
            identityName: 'Aura',
            iconUri: Uri.parse('logo.png'),
            authToken: _authToken!,
          );
          if (reauth != null) {
            sessionAuthToken = reauth.authToken;
          }
        } catch (e) {
          debugPrint(
            '[MWA] Reauthorize failed ($e), falling back to authorize',
          );
        }
      } else if (_authToken != null && cluster != _authCluster) {
        debugPrint(
          '[MWA] Cluster changed ($_authCluster → $cluster), skipping reauthorize',
        );
      }

      if (sessionAuthToken == null) {
        // No stored token, reauthorize failed, or cluster changed — full authorize.
        debugPrint('[MWA] Using full authorize flow (cluster=$cluster)');
        final auth = await client.authorize(
          identityUri: _identityUri,
          identityName: 'Aura',
          iconUri: Uri.parse('logo.png'),
          cluster: cluster,
        );
        if (auth == null) {
          throw MwaException('Wallet authorization cancelled');
        }
        sessionAuthToken = auth.authToken;
        _publicKey = _base58encode(Uint8List.fromList(auth.publicKey));
        _authCluster = cluster;
      }

      // Persist for future calls.
      _authToken = sessionAuthToken;
      _storeAuthTokenSync();

      // Sign and send — wallet app signs + broadcasts to Solana.
      final result = await client.signAndSendTransactions(
        transactions: transactions,
      );

      // Extract transaction signatures from result.
      final signatures = <String>[];
      for (final sig in result.signatures) {
        signatures.add(_base58encode(Uint8List.fromList(sig)));
      }

      if (signatures.isEmpty) {
        throw MwaException(
          'Wallet returned no signatures — transaction may have been rejected',
        );
      }

      return signatures;
    } on PlatformException catch (e) {
      // Surface the actual wallet error (simulation failure, insufficient funds, etc.)
      final detail = e.message ?? e.code;
      throw MwaException('Wallet rejected transaction: $detail');
    } finally {
      await session.close();
    }
  }

  /// Fire-and-forget persist of auth token + cluster.
  void _storeAuthTokenSync() {
    if (_authToken != null) {
      _storage.write(key: 'mwa_auth_token', value: _authToken!).ignore();
    }
    if (_publicKey != null) {
      _storage.write(key: 'mwa_public_key', value: _publicKey!).ignore();
    }
    _storage.write(key: 'mwa_auth_cluster', value: _authCluster).ignore();
  }

  /// Sign transactions without sending — useful when the app (or backend)
  /// will submit the signed TX itself.
  ///
  /// This bypasses the wallet app's transaction simulation, which can fail
  /// for sponsored (partially-signed) or devnet transactions.
  ///
  /// Returns the list of fully-signed transaction bytes.
  Future<List<Uint8List>> signTransactions(
    List<Uint8List> transactions, {
    String cluster = 'mainnet-beta',
  }) async {
    if (!isAvailable) {
      throw MwaException('MWA is only available on Android');
    }

    final session = await LocalAssociationScenario.create();
    try {
      session.startActivityForResult(null).ignore();
      final client = await session.start();

      String? sessionAuthToken;

      if (_authToken != null && cluster == _authCluster) {
        try {
          final reauth = await client.reauthorize(
            identityUri: _identityUri,
            identityName: 'Aura',
            iconUri: Uri.parse('logo.png'),
            authToken: _authToken!,
          );
          if (reauth != null) {
            sessionAuthToken = reauth.authToken;
          }
        } catch (e) {
          debugPrint(
            '[MWA] Reauthorize failed ($e), falling back to authorize',
          );
        }
      } else if (_authToken != null && cluster != _authCluster) {
        debugPrint(
          '[MWA] Cluster changed ($_authCluster → $cluster), skipping reauthorize',
        );
      }

      if (sessionAuthToken == null) {
        debugPrint('[MWA] Using full authorize flow (cluster=$cluster)');
        final auth = await client.authorize(
          identityUri: _identityUri,
          identityName: 'Aura',
          iconUri: Uri.parse('logo.png'),
          cluster: cluster,
        );
        if (auth == null) {
          throw MwaException('Wallet authorization cancelled');
        }
        sessionAuthToken = auth.authToken;
        _publicKey = _base58encode(Uint8List.fromList(auth.publicKey));
        _authCluster = cluster;
      }

      _authToken = sessionAuthToken;
      _storeAuthTokenSync();

      // Sign only — wallet app signs but does NOT broadcast.
      final result = await client.signTransactions(transactions: transactions);

      if (result.signedPayloads.isEmpty) {
        throw MwaException(
          'Wallet returned no signed payloads — signing may have been rejected',
        );
      }

      return result.signedPayloads.map((p) => Uint8List.fromList(p)).toList();
    } on PlatformException catch (e) {
      final detail = e.message ?? e.code;
      throw MwaException('Wallet rejected signing: $detail');
    } finally {
      await session.close();
    }
  }

  /// Clear local wallet state and persisted auth token.
  Future<void> disconnect() async {
    _publicKey = null;
    _authToken = null;
    _authCluster = 'mainnet-beta';
    await _storage.delete(key: 'mwa_auth_token');
    await _storage.delete(key: 'mwa_public_key');
    await _storage.delete(key: 'mwa_auth_cluster');
  }
}

/// Exception thrown by MWA operations.
class MwaException implements Exception {
  final String message;
  const MwaException(this.message);

  @override
  String toString() => 'MwaException: $message';
}

/// Riverpod provider — singleton for the app lifetime.
final mwaWalletServiceProvider = Provider<MwaWalletService>((_) {
  return MwaWalletService();
});

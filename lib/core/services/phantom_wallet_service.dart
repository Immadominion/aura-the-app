import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phantom_flutter_sdk/phantom_flutter_sdk.dart';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// Phantom embedded-wallet app-ID (from Phantom Portal → Set Up → App ID).
/// Override via `--dart-define`.
const String _kPhantomAppId = String.fromEnvironment(
  'PHANTOM_APP_ID',
  defaultValue: '3eaeec58-7d1f-4c1a-a63a-cf517c3355e3',
);

/// Phantom wallet API base URL (KMS RPC requests are sent to `{base}/kms/rpc`).
const String _kKmsApiBaseUrl = String.fromEnvironment(
  'PHANTOM_KMS_BASE_URL',
  defaultValue: 'https://api.phantom.app/v1/wallets',
);

/// Phantom Auth2 login page. The RN SDK default is `/login/start`.
const String _kAuth2LoginUrl = String.fromEnvironment(
  'PHANTOM_AUTH2_LOGIN_URL',
  defaultValue: 'https://connect.phantom.app/login/start',
);

/// Phantom Auth2 API.
const String _kAuth2ApiBaseUrl = String.fromEnvironment(
  'PHANTOM_AUTH2_API_URL',
  defaultValue: 'https://auth.phantom.app',
);

/// Deep-link redirect URI registered in AndroidManifest / Info.plist.
/// Format matches RN SDK convention: `{scheme}://phantom-auth-callback`.
const String _kRedirectUri = String.fromEnvironment(
  'PHANTOM_REDIRECT_URI',
  defaultValue: 'aura://phantom-auth-callback',
);

// ---------------------------------------------------------------------------
// Result type returned to AuthService
// ---------------------------------------------------------------------------

/// Combines the wallet address and a function to sign arbitrary bytes
/// so that AuthService can perform the SIWS flow.
class PhantomConnectResult {
  /// Base58-encoded Solana public key.
  final String walletAddress;

  PhantomConnectResult({required this.walletAddress});
}

// ---------------------------------------------------------------------------
// PhantomWalletService
// ---------------------------------------------------------------------------

/// Wraps the Phantom Flutter SDK [EmbeddedProviderV2] for Aura's needs.
///
/// Responsibilities:
///   - Initialise SDK adapter / provider / wallet client once.
///   - Expose connect (social login → embedded wallet), disconnect, signMessage.
///   - Translate between SDK types and what [AuthService] expects.
///
/// NOT responsible for SIWS flow — that stays in AuthService.
class PhantomWalletService {
  EmbeddedProviderV2? _provider;

  /// The Solana wallet address from the last successful connect.
  String? _walletAddress;
  String? get walletAddress => _walletAddress;

  /// Whether the embedded provider is currently connected.
  bool get isConnected => _provider?.isConnected() ?? false;

  /// Lazily build and return the SDK provider.
  Future<EmbeddedProviderV2> _ensureProvider() async {
    if (_provider != null) return _provider!;

    final adapter = FlutterPlatformAdapterV2(
      auth2Options: Auth2AuthProviderOptions(
        clientId: _kPhantomAppId, // RN SDK uses appId as clientId
        redirectUri: _kRedirectUri,
        connectLoginUrl: _kAuth2LoginUrl,
        authApiBaseUrl: _kAuth2ApiBaseUrl,
      ),
      kmsClientOptions: Auth2KmsClientOptions(
        apiBaseUrl: _kKmsApiBaseUrl,
        appId: _kPhantomAppId,
      ),
    );

    final walletClient = PhantomClientWalletFacade(
      stamper: adapter.stamper,
    );

    final provider = EmbeddedProviderV2(
      config: EmbeddedProviderConfig(
        appId: _kPhantomAppId,
        apiBaseUrl: _kKmsApiBaseUrl,
        addressTypes: ['solana'], // Aura only needs Solana
      ),
      platform: adapter,
      walletClient: walletClient,
    );

    await provider.init();
    _provider = provider;
    return provider;
  }

  /// Try to restore an existing embedded-wallet session.
  ///
  /// Returns the Solana wallet address if successful, null otherwise.
  Future<String?> tryAutoConnect() async {
    try {
      final provider = await _ensureProvider();
      await provider.autoConnect();
      if (provider.isConnected()) {
        final solAddr = provider
            .getAddresses()
            .where((a) => a.addressType == 'solana')
            .firstOrNull;
        if (solAddr != null) {
          _walletAddress = solAddr.address;
          return solAddr.address;
        }
      }
    } catch (e) {
      debugPrint('[PhantomWallet] autoConnect failed: $e');
    }
    return null;
  }

  /// Connect via social login (Google / Apple).
  ///
  /// Opens the OAuth browser flow, creates/restores the embedded wallet,
  /// and returns the Solana wallet address.
  Future<PhantomConnectResult> connect(String authProvider) async {
    debugPrint('[PhantomWallet] connect($authProvider) — '
        'appId=$_kPhantomAppId, '
        'authUrl=$_kAuth2LoginUrl, '
        'redirect=$_kRedirectUri, '
        'kmsBase=$_kKmsApiBaseUrl, '
        'authApi=$_kAuth2ApiBaseUrl');

    final provider = await _ensureProvider();

    final result = await provider.connect(
      AuthOptions(provider: authProvider),
    );

    final solAddr =
        result.addresses.where((a) => a.addressType == 'solana').firstOrNull;
    if (solAddr == null) {
      throw Exception(
        'Phantom embedded wallet did not return a Solana address.',
      );
    }

    _walletAddress = solAddr.address;
    return PhantomConnectResult(walletAddress: solAddr.address);
  }

  /// Sign an arbitrary UTF-8 message with the connected Solana wallet.
  ///
  /// Returns the signature as a string (base64url from KMS).
  Future<String> signMessage(String message) async {
    final provider = await _ensureProvider();
    if (!provider.isConnected()) {
      throw StateError('Not connected. Call connect() first.');
    }

    final encoded = base64Url.encode(utf8.encode(message));
    return provider.signMessage(
      SignMessageParams(encodedMessage: encoded, addressType: 'solana'),
    );
  }

  /// Disconnect and clear the embedded-wallet session.
  Future<void> disconnect() async {
    final provider = _provider;
    if (provider != null && provider.isConnected()) {
      await provider.disconnect();
    }
    _walletAddress = null;
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final phantomWalletServiceProvider = Provider<PhantomWalletService>((ref) {
  return PhantomWalletService();
});

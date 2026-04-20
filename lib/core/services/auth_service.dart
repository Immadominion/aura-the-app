import 'dart:convert';

import 'package:bs58/bs58.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../config/env_config.dart';
import 'api_client.dart';
import 'mwa_wallet_service.dart';
import 'phantom_wallet_service.dart';
import 'push_notification_service.dart';

/// SIWS (Sign-In With Solana) authentication service.
///
/// Uses [MwaWalletService.connectAndSign] for single-session MWA + SIWS
/// orchestration. All HTTP calls happen while Aura is in the foreground —
/// the MWA phase is network-free, solving Seeker's background networking
/// issue.
///
/// Flow:
///   Phase 1 (foreground): POST /auth/nonce → get nonce + issuedAt
///   Phase 2 (MWA):        authorize + build SIWS message + sign (no HTTP)
///   Phase 3 (foreground):  POST /auth/verify → get JWT tokens
class AuthService {
  final ApiClient _api;
  final MwaWalletService _mwa;
  final PhantomWalletService _phantom;

  static const _cachedUserKey = 'cached_user_json';

  AuthService({
    required ApiClient api,
    required MwaWalletService mwa,
    required PhantomWalletService phantom,
  })  : _api = api,
        _mwa = mwa,
        _phantom = phantom;

  /// Connected wallet address (from last successful sign-in).
  String? get walletAddress => _mwa.publicKey ?? _phantom.walletAddress;

  /// MWA auth token from last SIWS sign-in (for transaction signing).
  String? get mwaAuthToken => _mwa.authToken;

  /// Build a SIWS message matching the backend's expected format.
  static String _buildSiwsMessage(
    String walletAddress,
    String nonce,
    String issuedAt,
  ) {
    final chainId = EnvConfig.solanaNetwork == 'mainnet-beta'
        ? 'mainnet'
        : EnvConfig.solanaNetwork;
    return [
      'useaura.wtf wants you to sign in with your Solana account:',
      walletAddress,
      '',
      'Sign in to Aura — your autonomous LP trading agent.',
      '',
      'URI: https://useaura.wtf',
      'Version: 1',
      'Chain ID: $chainId',
      'Nonce: $nonce',
      'Issued At: $issuedAt',
    ].join('\n');
  }

  /// Full SIWS auth flow using MWA directly.
  ///
  /// 1. Fetches a server nonce **before** opening MWA (foreground).
  /// 2. MWA session: authorize → build SIWS message locally → sign.
  /// 3. Verifies signature **after** MWA closes (foreground).
  Future<User> signIn() async {
    // Phase 1: fetch nonce from backend (no wallet address needed).
    debugPrint('[Auth] Phase 1: fetching nonce (foreground)');
    final nonceResponse = await _api.post('/auth/nonce', data: {});
    final nonceData = nonceResponse.data as Map<String, dynamic>;
    final nonce = nonceData['nonce'] as String;
    final issuedAt = nonceData['issuedAt'] as String;
    debugPrint('[Auth] Got nonce: ${nonce.substring(0, 8)}...');

    // Phase 2: single MWA session — authorize + sign SIWS message.
    late String siwsMessage;
    final siwsResult = await _mwa.connectAndSign(
      getMessageToSign: (walletAddress) async {
        siwsMessage = _buildSiwsMessage(walletAddress, nonce, issuedAt);
        return Uint8List.fromList(utf8.encode(siwsMessage));
      },
    );

    // Phase 3: verify signature with backend.
    debugPrint('[Auth] Phase 3: verifying signature (foreground)');
    final verifyResponse = await _api.post(
      '/auth/verify',
      data: {
        'walletAddress': siwsResult.publicKey,
        'signature': base58.encode(siwsResult.signature),
        'message': siwsMessage,
      },
    );
    final verifyData = verifyResponse.data as Map<String, dynamic>;

    // Store JWT tokens.
    await _api.setTokens(
      accessToken: verifyData['accessToken'] as String,
      refreshToken: verifyData['refreshToken'] as String,
    );

    // Persist MWA auth token for transaction signing.
    await _mwa.setAuthToken(
      siwsResult.authToken,
      publicKey: siwsResult.publicKey,
    );

    debugPrint('[Auth] Authenticated as ${siwsResult.publicKey}');
    final userJson = verifyData['user'];
    User user;
    if (userJson is Map<String, dynamic>) {
      user = User.fromJson(userJson);
    } else {
      user = await getCurrentUser();
    }

    // Cache user for offline resilience.
    await _cacheUser(user);

    return user;
  }

  /// SIWS auth flow via Phantom embedded wallet (social login).
  ///
  /// [authProvider] is `'google'` or `'apple'`.
  ///
  /// Flow:
  ///   1. Connect embedded wallet via social OAuth.
  ///   2. Fetch nonce from backend.
  ///   3. Build SIWS message and sign with embedded wallet's Ed25519 key.
  ///   4. Verify signature with backend → JWT.
  Future<User> signInWithPhantom(String authProvider) async {
    // Step 1: Connect embedded wallet (opens OAuth browser flow).
    debugPrint('[Auth] Phantom: connecting via $authProvider');
    final connectResult = await _phantom.connect(authProvider);
    final walletAddress = connectResult.walletAddress;
    debugPrint('[Auth] Phantom: connected, wallet=$walletAddress');

    // Step 2: Fetch nonce from backend.
    debugPrint('[Auth] Phantom: fetching nonce');
    final nonceResponse = await _api.post('/auth/nonce', data: {
      'walletAddress': walletAddress,
    });
    final nonceData = nonceResponse.data as Map<String, dynamic>;
    final nonce = nonceData['nonce'] as String;
    final issuedAt = nonceData['issuedAt'] as String;

    // Step 3: Build SIWS message and sign with embedded wallet.
    final siwsMessage = _buildSiwsMessage(walletAddress, nonce, issuedAt);
    debugPrint('[Auth] Phantom: signing SIWS message');
    final signature = await _phantom.signMessage(siwsMessage);

    // Step 4: Verify with backend.
    debugPrint('[Auth] Phantom: verifying signature');
    final verifyResponse = await _api.post(
      '/auth/verify',
      data: {
        'walletAddress': walletAddress,
        'signature': signature,
        'message': siwsMessage,
      },
    );
    final verifyData = verifyResponse.data as Map<String, dynamic>;

    // Store JWT tokens.
    await _api.setTokens(
      accessToken: verifyData['accessToken'] as String,
      refreshToken: verifyData['refreshToken'] as String,
    );

    debugPrint('[Auth] Phantom: authenticated as $walletAddress');
    final userJson = verifyData['user'];
    User user;
    if (userJson is Map<String, dynamic>) {
      user = User.fromJson(userJson);
    } else {
      user = await getCurrentUser();
    }

    await _cacheUser(user);
    return user;
  }

  /// Get current user info (requires auth).
  Future<User> getCurrentUser() async {
    final response = await _api.get('/auth/me');
    final data = response.data as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    // Update cache with fresh data.
    await _cacheUser(user);
    return user;
  }

  /// Sign out — clear tokens and cached user.
  Future<void> signOut() async {
    await _api.clearTokens();
    await _clearCachedUser();
  }

  /// Check if user has stored tokens (may be expired).
  Future<bool> hasStoredSession() async {
    await _api.loadTokens();
    return _api.isAuthenticated;
  }

  /// Try to restore session by loading tokens and verifying with /auth/me.
  ///
  /// Only clears stored tokens on an explicit 401 (bad/expired credentials).
  /// Network errors, timeouts, server down → return **cached user** so the
  /// app stays authenticated and usable offline. The next network-restore
  /// event will re-validate the session.
  Future<User?> tryRestoreSession() async {
    await _api.loadTokens();
    if (!_api.isAuthenticated) return null;

    try {
      return await getCurrentUser();
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        // Network error / server unreachable — return cached user so the
        // app doesn't kick the user to connect-wallet.
        debugPrint(
          '[Auth] Session restore skipped: ${e.type} (returning cached user)',
        );
        return _getCachedUser();
      }
      // 401 → token is genuinely expired, attempt refresh.
      debugPrint('[Auth] Access token expired, attempting refresh...');
      final refreshed = await _api.refreshAccessToken();
      if (refreshed) {
        try {
          return await getCurrentUser();
        } on DioException catch (e2) {
          if (e2.response?.statusCode == 401) {
            // Refresh token also rejected — user must re-authenticate.
            debugPrint('[Auth] Refresh token rejected, clearing session.');
            await _api.clearTokens();
            await _clearCachedUser();
          } else {
            // Network error after refresh — return cached user.
            return _getCachedUser();
          }
        }
      } else {
        // Refresh failed (e.g. network error during refresh) — try cached.
        return _getCachedUser();
      }
      return null;
    } catch (_) {
      // Unknown non-Dio error — return cached user if available.
      return _getCachedUser();
    }
  }

  // ── User caching for offline resilience ──────────────────────

  static const _cachedAtKey = 'cached_user_at';
  static const _staleThreshold = Duration(minutes: 30);

  Future<void> _cacheUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(user.toJson());
      await prefs.setString(_cachedUserKey, json);
      await prefs.setInt(_cachedAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[Auth] Failed to cache user: $e');
    }
  }

  Future<User?> _getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cachedUserKey);
      if (json == null) return null;

      final cachedAt = prefs.getInt(_cachedAtKey);
      if (cachedAt != null) {
        final age = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(cachedAt),
        );
        if (age > _staleThreshold) {
          debugPrint(
            '[Auth] Cached user is stale (${age.inMinutes}min old) — discarding',
          );
          return null;
        }
      }

      final map = jsonDecode(json) as Map<String, dynamic>;
      debugPrint('[Auth] Returning cached user (offline mode)');
      return User.fromJson(map);
    } catch (e) {
      debugPrint('[Auth] Failed to read cached user: $e');
      return null;
    }
  }

  Future<void> _clearCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUserKey);
    } catch (_) {}
  }
}

/// Authentication exception with user-friendly message.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// AuthService Riverpod provider.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    api: ref.read(apiClientProvider),
    mwa: ref.read(mwaWalletServiceProvider),
    phantom: ref.read(phantomWalletServiceProvider),
  );
});

/// Auth state: null = not authenticated, User = authenticated.
///
/// Uses [AsyncNotifier] (Riverpod 3.x compatible).
final authStateProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  () => AuthNotifier(),
);

final connectedWalletAddressProvider = Provider<String?>((ref) {
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser?.walletAddress != null && authUser!.walletAddress.isNotEmpty) {
    return authUser.walletAddress;
  }

  final auth = ref.read(authServiceProvider);
  if (auth.walletAddress != null && auth.walletAddress!.isNotEmpty) {
    return auth.walletAddress;
  }

  final phantom = ref.read(phantomWalletServiceProvider);
  if (phantom.walletAddress != null && phantom.walletAddress!.isNotEmpty) {
    return phantom.walletAddress;
  }

  final mwa = ref.read(mwaWalletServiceProvider);
  return mwa.publicKey;
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final auth = ref.read(authServiceProvider);

    // Load persisted MWA auth token so signAndSendTransactions works
    // across hot-reloads and app restarts.
    final mwa = ref.read(mwaWalletServiceProvider);
    await mwa.loadAuthToken();

    return auth.tryRestoreSession();
  }

  Future<void> signIn() async {
    final auth = ref.read(authServiceProvider);
    state = const AsyncValue.loading();
    try {
      final user = await auth.signIn();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Sign in via Phantom embedded wallet (Google / Apple social login).
  Future<void> signInWithPhantom(String authProvider) async {
    final auth = ref.read(authServiceProvider);
    state = const AsyncValue.loading();
    try {
      final user = await auth.signInWithPhantom(authProvider);
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final auth = ref.read(authServiceProvider);
    await auth.signOut();

    // Unregister FCM device token so the server stops sending pushes.
    final push = ref.read(pushNotificationServiceProvider);
    await push.unregister();

    // Clear MWA auth token.
    final mwa = ref.read(mwaWalletServiceProvider);
    await mwa.disconnect();

    // Clear Phantom embedded wallet session.
    final phantom = ref.read(phantomWalletServiceProvider);
    await phantom.disconnect();

    state = const AsyncValue.data(null);
  }

  /// Re-validate the current session against the backend.
  /// Called when network is restored to ensure auth state is fresh.
  Future<void> revalidate() async {
    final auth = ref.read(authServiceProvider);
    try {
      final user = await auth.tryRestoreSession();
      state = AsyncValue.data(user);
    } catch (_) {
      // Keep current state on errors.
    }
  }

  /// Synchronously mark setup as completed in the local auth state.
  /// Avoids the loading-state race that happens with invalidate().
  void markSetupCompleted() {
    final current = state.value;
    if (current != null && !current.setupCompleted) {
      state = AsyncValue.data(
        User(
          id: current.id,
          walletAddress: current.walletAddress,
          displayName: current.displayName,
          setupCompleted: true,
          execMode: current.execMode,
          createdAt: current.createdAt,
        ),
      );
    }
  }
}

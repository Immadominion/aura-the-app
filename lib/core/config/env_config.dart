/// Environment configuration for the Sage app.
///
/// Manages base URLs, feature flags, and environment-specific settings.
/// Configured via `--dart-define` at build time:
///
/// ```bash
/// # Development — uses Railway-hosted backend by default
/// flutter run
///
/// # Production
/// flutter run --dart-define=ENV=production
///
/// # Custom backend URL (e.g., local dev on LAN)
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3001
/// ```
library;

import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class EnvConfig {
  /// Current environment, set via `--dart-define=ENV=<value>`
  static const String _envName = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  /// Override API base URL via `--dart-define=API_BASE_URL=<url>`
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Override ML service URL via `--dart-define=ML_BASE_URL=<url>`
  static const String _mlBaseUrlOverride = String.fromEnvironment(
    'ML_BASE_URL',
  );

  static Environment get environment {
    switch (_envName) {
      case 'production':
        return Environment.production;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.development;
    }
  }

  static bool get isProduction => environment == Environment.production;
  static bool get isDevelopment => environment == Environment.development;
  static bool get isStaging => environment == Environment.staging;

  /// Backend API base URL.
  ///
  /// Set via `--dart-define=API_BASE_URL=<url>` at build time.
  /// Falls back to localhost for development builds.
  ///
  /// ```bash
  /// # Production
  /// flutter run --dart-define=API_BASE_URL=https://your-backend.up.railway.app
  ///
  /// # Local dev (use your Mac's LAN IP for Android)
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3001
  /// ```
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;

    switch (environment) {
      case Environment.production:
        // Must be provided via --dart-define=API_BASE_URL
        throw StateError(
          'API_BASE_URL must be set via --dart-define for production builds',
        );
      case Environment.staging:
        throw StateError(
          'API_BASE_URL must be set via --dart-define for staging builds',
        );
      case Environment.development:
        return 'http://localhost:3001';
    }
  }

  /// ML prediction service base URL.
  ///
  /// In all hosted environments ML is proxied through the backend's /ml route.
  static String get mlBaseUrl {
    if (_mlBaseUrlOverride.isNotEmpty) return _mlBaseUrlOverride;
    return '$apiBaseUrl/ml';
  }

  /// Solana network name.
  static String get solanaNetwork {
    switch (environment) {
      case Environment.production:
        return 'mainnet-beta';
      case Environment.staging:
      case Environment.development:
        return 'devnet';
    }
  }

  /// Solana RPC endpoint override via `--dart-define=SOLANA_RPC_URL=<url>`.
  static const String _solanaRpcUrlOverride = String.fromEnvironment(
    'SOLANA_RPC_URL',
  );

  /// Solana RPC endpoint.
  ///
  /// Production builds MUST supply `--dart-define=SOLANA_RPC_URL=<url>`.
  static String get solanaRpcUrl {
    if (_solanaRpcUrlOverride.isNotEmpty) return _solanaRpcUrlOverride;

    switch (environment) {
      case Environment.production:
        throw StateError(
          'SOLANA_RPC_URL must be set via --dart-define for production builds',
        );
      case Environment.staging:
      case Environment.development:
        return 'https://api.devnet.solana.com';
    }
  }

  /// Whether to enable debug logging.
  static bool get enableDebugLogging => !isProduction || kDebugMode;

  /// Whether to show the debug banner on home screen.
  static bool get showDebugBanner => isDevelopment;

  /// Connection timeout for API calls.
  static Duration get apiConnectTimeout =>
      isProduction ? const Duration(seconds: 15) : const Duration(seconds: 10);

  /// Receive timeout for API calls.
  static Duration get apiReceiveTimeout =>
      isProduction ? const Duration(seconds: 30) : const Duration(seconds: 60);

  /// Label for UI display (settings screen).
  static String get environmentLabel {
    switch (environment) {
      case Environment.production:
        return 'Production';
      case Environment.staging:
        return 'Staging';
      case Environment.development:
        return 'Development';
    }
  }
}

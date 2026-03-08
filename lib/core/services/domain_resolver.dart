import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solana/solana.dart';
import 'package:tld_parser/tld_parser.dart';

import 'package:sage/core/config/env_config.dart';

/// Resolves Solana wallet addresses → AllDomains ANS names.
///
/// Uses `tld_parser_dart` to do a reverse lookup (main domain).
/// Results are cached in-memory so the same address is only resolved once.
class DomainResolver {
  DomainResolver._();

  static final _instance = DomainResolver._();
  factory DomainResolver() => _instance;

  late final RpcClient _rpc = RpcClient(EnvConfig.solanaRpcUrl);
  late final TldParser _parser = TldParser(_rpc);

  /// Cache: wallet address → domain name (null = no domain found).
  final Map<String, String?> _cache = {};

  /// Resolve a wallet address to its AllDomains main domain.
  ///
  /// Returns the full domain (e.g. `miester.abc`) or `null` if no
  /// main domain is set for this wallet.
  ///
  /// Results are cached — subsequent calls for the same address
  /// return instantly from memory.
  Future<String?> resolve(String walletAddress) async {
    // Check cache first
    if (_cache.containsKey(walletAddress)) {
      return _cache[walletAddress];
    }

    try {
      final pubkey = Ed25519HDPublicKey.fromBase58(walletAddress);
      final mainDomain = await _parser.tryGetMainDomain(pubkey);

      final domain = mainDomain?.fullDomain;
      _cache[walletAddress] = domain;
      return domain;
    } catch (e) {
      debugPrint('[DomainResolver] Failed to resolve $walletAddress: $e');
      _cache[walletAddress] = null;
      return null;
    }
  }

  /// Get cached result without making a network call.
  String? getCached(String walletAddress) => _cache[walletAddress];

  /// Whether a result (including null) is cached for this address.
  bool isCached(String walletAddress) => _cache.containsKey(walletAddress);
}

/// Provider for the singleton DomainResolver.
final domainResolverProvider = Provider<DomainResolver>((ref) {
  return DomainResolver();
});

/// FutureProvider that resolves a wallet address → domain name.
/// Auto-caches so it won't re-fetch on rebuild.
final domainNameProvider = FutureProvider.family<String?, String>((
  ref,
  walletAddress,
) async {
  final resolver = ref.read(domainResolverProvider);
  return resolver.resolve(walletAddress);
});

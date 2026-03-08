import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// ML model health and prediction data from the backend.
class MlHealth {
  final String status;
  final String modelVersion;
  final int featureCount;
  final double threshold;
  final double rocAuc;
  final double precision;

  const MlHealth({
    required this.status,
    required this.modelVersion,
    required this.featureCount,
    required this.threshold,
    required this.rocAuc,
    required this.precision,
  });

  factory MlHealth.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] as Map<String, dynamic>? ?? {};
    return MlHealth(
      status: json['status'] as String? ?? 'unknown',
      modelVersion: json['modelVersion'] as String? ?? 'unknown',
      featureCount: json['featureCount'] as int? ?? 0,
      threshold: (metrics['threshold'] as num?)?.toDouble() ?? 0,
      rocAuc: (metrics['rocAuc'] as num?)?.toDouble() ?? 0,
      precision: (metrics['precision'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get isHealthy => status == 'ok';
}

/// Repository for ML model operations.
class MlRepository {
  final ApiClient _api;

  MlRepository(this._api);

  /// Check ML model health and metrics.
  Future<MlHealth> getHealth() async {
    final response = await _api.get('/ml/health');
    return MlHealth.fromJson(response.data as Map<String, dynamic>);
  }
}

// ═══════════════════════════════════════════════════════════════
// Riverpod Providers
// ═══════════════════════════════════════════════════════════════

final mlRepositoryProvider = Provider<MlRepository>((ref) {
  return MlRepository(ref.read(apiClientProvider));
});

/// Provider for ML model health status.
final mlHealthProvider = FutureProvider<MlHealth>((ref) async {
  final repo = ref.read(mlRepositoryProvider);
  return repo.getHealth();
});

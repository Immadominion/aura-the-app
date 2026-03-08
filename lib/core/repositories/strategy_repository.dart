import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/strategy.dart';
import '../services/api_client.dart';

/// Repository for strategy preset operations.
class StrategyRepository {
  final ApiClient _api;

  StrategyRepository(this._api);

  /// List all strategy presets (system + user's custom).
  Future<List<StrategyPreset>> listPresets() async {
    final response = await _api.get('/strategy/presets');
    final data = response.data as Map<String, dynamic>;
    final presets = data['presets'] as List<dynamic>;
    return presets
        .map((e) => StrategyPreset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a custom strategy preset.
  Future<StrategyPreset> createPreset(Map<String, dynamic> preset) async {
    final response = await _api.post('/strategy/create', data: preset);
    final data = response.data as Map<String, dynamic>;
    return StrategyPreset.fromJson(data['preset'] as Map<String, dynamic>);
  }
}

/// StrategyRepository Riverpod provider.
final strategyRepositoryProvider = Provider<StrategyRepository>((ref) {
  return StrategyRepository(ref.read(apiClientProvider));
});

/// Strategy presets list provider.
final strategyPresetsProvider =
    FutureProvider<List<StrategyPreset>>((ref) async {
  final repo = ref.read(strategyRepositoryProvider);
  return repo.listPresets();
});

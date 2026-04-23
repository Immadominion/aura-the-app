import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bot_decision.dart';
import '../services/api_client.dart';

class DecisionRepository {
  final ApiClient _api;

  DecisionRepository(this._api);

  Future<List<BotDecision>> getDecisions(
    String botId, {
    String? scanId,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (scanId != null) params['scanId'] = scanId;

    final response = await _api.get(
      '/bot/$botId/decisions',
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final rows = data['decisions'] as List<dynamic>;
    return rows
        .map((e) => BotDecision.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BotDecision> getPositionDecision(String positionId) async {
    final response = await _api.get('/position/$positionId/decision');
    final data = response.data as Map<String, dynamic>;
    return BotDecision.fromJson(data['decision'] as Map<String, dynamic>);
  }
}

final decisionRepositoryProvider = Provider<DecisionRepository>((ref) {
  return DecisionRepository(ref.read(apiClientProvider));
});

final botDecisionsProvider = FutureProvider.family<List<BotDecision>, String>((
  ref,
  botId,
) async {
  final repo = ref.read(decisionRepositoryProvider);
  return repo.getDecisions(botId);
});

final positionDecisionProvider = FutureProvider.family<BotDecision, String>((
  ref,
  positionId,
) async {
  final repo = ref.read(decisionRepositoryProvider);
  return repo.getPositionDecision(positionId);
});

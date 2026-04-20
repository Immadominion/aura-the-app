import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura/core/services/api_client.dart';
import 'package:aura/features/chat/models/chat_models.dart';

/// Cloud-first persistence for chat state and setup wizard progress.
///
/// **Conversations**: Messages live server-side in PostgreSQL. On launch,
/// we derive the active conversation by fetching the most recent one per
/// type from `GET /ai/conversations`. Local SharedPreferences is a
/// read-ahead cache so the UI can display instantly while the server
/// response arrives.
///
/// **Setup wizard state**: Saved to a JSONB column on the `users` table
/// via `PUT /auth/setup-progress`. Same local cache pattern.
///
/// This ensures the same account on a different device sees the same state.
class ChatPersistence {
  final ApiClient _api;

  ChatPersistence(this._api);

  // ── Local cache keys ──
  static const _keyGeneralConvId = 'aura_active_general_conversation_id';
  static const _keySetupConvId = 'aura_active_setup_conversation_id';
  static const _keySetupProgress = 'aura_setup_progress_json';

  // ════════════════════════════════════════════════════
  // Conversation IDs (derived from server conversation list)
  // ════════════════════════════════════════════════════

  /// Resolve the most recent conversation ID for the given type by
  /// querying the server. Falls back to the local cache if offline.
  Future<String?> resolveActiveConversationId(String type) async {
    try {
      // Try server first — source of truth
      final response = await _api.get('/ai/conversations');
      final data = response.data as Map<String, dynamic>;
      final list = data['conversations'] as List? ?? [];

      // Find the most recent conversation of this type
      // (server returns them sorted by updatedAt DESC)
      for (final conv in list) {
        final c = conv as Map<String, dynamic>;
        if (c['type'] == type) {
          final id = c['conversationId'] as String;
          // Cache it locally for fast startup next time
          await _cacheConversationId(type, id);
          return id;
        }
      }

      // No conversation of this type exists on server
      await _cacheConversationId(type, null);
      return null;
    } catch (_) {
      // Offline / error — fall back to local cache
      return _cachedConversationId(type);
    }
  }

  /// Save the conversation ID both locally (cache) and implicitly on
  /// server (conversations are persisted when messages are sent).
  Future<void> saveConversationId(String type, String? conversationId) async {
    await _cacheConversationId(type, conversationId);
  }

  /// Clear the cached conversation ID for a type.
  Future<void> clearConversationId(String type) async {
    await _cacheConversationId(type, null);
  }

  // ════════════════════════════════════════════════════
  // Setup Wizard State (cloud-synced)
  // ════════════════════════════════════════════════════

  /// Save setup wizard state to server AND local cache.
  Future<void> saveSetupState({
    required int step,
    String? path,
    String? execMode,
    bool? useAiChat,
    StrategyParams? params,
  }) async {
    final payload = <String, dynamic>{
      'step': step,
      'path': ?path,
      'execMode': ?execMode,
      'useAiChat': ?useAiChat,
      if (params != null && !params.isEmpty) 'params': params.toJson(),
    };

    // Cache locally first (instant)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySetupProgress, jsonEncode(payload));

    // Sync to server (fire-and-forget, tolerant of failure)
    try {
      await _api.put('/auth/setup-progress', data: payload);
    } catch (_) {
      // Will re-sync on next save or next app launch
    }
  }

  /// Load setup wizard state. Tries server first, falls back to local cache.
  Future<SetupWizardState?> loadSetupState() async {
    Map<String, dynamic>? data;

    try {
      // Server = source of truth
      final response = await _api.get('/auth/me');
      final userData = response.data as Map<String, dynamic>;
      final user = userData['user'] as Map<String, dynamic>?;
      final progress = user?['setupProgress'];
      if (progress != null && progress is Map<String, dynamic>) {
        data = progress;
        // Update local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keySetupProgress, jsonEncode(data));
      }
    } catch (_) {
      // Offline — try local cache
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keySetupProgress);
      if (json != null) {
        try {
          data = jsonDecode(json) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    if (data == null) return null;

    StrategyParams? params;
    final paramsMap = data['params'];
    if (paramsMap != null && paramsMap is Map<String, dynamic>) {
      params = StrategyParams.fromJson(paramsMap);
    }

    return SetupWizardState(
      step: (data['step'] as num?)?.toInt() ?? 0,
      path: data['path'] as String?,
      execMode: data['execMode'] as String?,
      useAiChat: data['useAiChat'] as bool? ?? false,
      params: params,
    );
  }

  /// Clear setup state on both server and local cache.
  Future<void> clearSetupState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySetupProgress);

    // Also clear cached setup conversation ID
    await _cacheConversationId('setup', null);

    try {
      await _api.delete('/auth/setup-progress');
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════
  // Private helpers
  // ════════════════════════════════════════════════════

  Future<void> _cacheConversationId(String type, String? id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = type == 'setup' ? _keySetupConvId : _keyGeneralConvId;
    if (id != null) {
      await prefs.setString(key, id);
    } else {
      await prefs.remove(key);
    }
  }

  Future<String?> _cachedConversationId(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = type == 'setup' ? _keySetupConvId : _keyGeneralConvId;
    return prefs.getString(key);
  }
}

/// Snapshot of the setup wizard's progress.
class SetupWizardState {
  final int step;
  final String? path;
  final String? execMode;
  final bool useAiChat;
  final StrategyParams? params;

  const SetupWizardState({
    required this.step,
    this.path,
    this.execMode,
    this.useAiChat = false,
    this.params,
  });
}

/// Provider — depends on ApiClient for server calls.
final chatPersistenceProvider = Provider<ChatPersistence>((ref) {
  return ChatPersistence(ref.read(apiClientProvider));
});

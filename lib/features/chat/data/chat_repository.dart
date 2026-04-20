import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aura/core/services/api_client.dart';
import 'package:aura/features/chat/models/chat_models.dart';

/// Repository for AI chat API calls.
class ChatRepository {
  final ApiClient _api;

  ChatRepository(this._api);

  /// Send a message to Aura AI.
  /// Returns the AI response and optional strategy params.
  /// [currentParams] sends the user's active strategy so the AI can modify
  /// values incrementally instead of starting from scratch.
  Future<
    ({
      String conversationId,
      String message,
      StrategyParams? strategyParams,
      List<AppAction> actions,
    })
  >
  sendMessage({
    required String message,
    String? conversationId,
    String type = 'general',
    StrategyParams? currentParams,
  }) async {
    final response = await _api.post(
      '/ai/chat',
      data: {
        'message': message,
        'conversationId': ?conversationId,
        'type': type,
        if (currentParams != null && !currentParams.isEmpty)
          'currentParams': currentParams.toJson(),
      },
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );

    final data = response.data as Map<String, dynamic>;
    final actionsList = data['actions'] as List?;
    return (
      conversationId: data['conversationId'] as String,
      message: data['message'] as String,
      strategyParams: data['strategyParams'] != null
          ? StrategyParams.fromJson(
              data['strategyParams'] as Map<String, dynamic>,
            )
          : null,
      actions: actionsList != null
          ? actionsList
                .map((e) => AppAction.fromJson(e as Map<String, dynamic>))
                .toList()
          : <AppAction>[],
    );
  }

  /// Transcribe audio file to text.
  Future<String> transcribe(File audioFile) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.path.split('/').last,
      ),
    });

    final response = await _api.post('/ai/transcribe', data: formData);
    final data = response.data as Map<String, dynamic>;
    return data['text'] as String;
  }

  /// List user's conversations.
  Future<List<ConversationSummary>> listConversations() async {
    final response = await _api.get('/ai/conversations');
    final data = response.data as Map<String, dynamic>;
    final list = data['conversations'] as List;
    return list
        .map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get full conversation by ID.
  Future<
    ({
      String conversationId,
      String type,
      String? title,
      List<ChatMessage> messages,
      StrategyParams? extractedParams,
    })
  >
  getConversation(String conversationId) async {
    final response = await _api.get('/ai/conversations/$conversationId');
    final data = response.data as Map<String, dynamic>;

    final messagesList = data['messages'] as List;
    final messages = messagesList
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();

    return (
      conversationId: data['conversationId'] as String,
      type: data['type'] as String,
      title: data['title'] as String?,
      messages: messages,
      extractedParams: data['extractedParams'] != null
          ? StrategyParams.fromJson(
              data['extractedParams'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Delete a conversation.
  Future<void> deleteConversation(String conversationId) async {
    await _api.delete('/ai/conversations/$conversationId');
  }

  /// Check AI service status.
  Future<AiStatus> getStatus() async {
    final response = await _api.get('/ai/status');
    final data = response.data as Map<String, dynamic>;
    return AiStatus.fromJson(data);
  }
}

/// ChatRepository provider.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(apiClientProvider));
});

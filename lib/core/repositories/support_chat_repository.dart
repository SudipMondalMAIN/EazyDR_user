import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core_providers.dart';
import '../models/chat_message.dart';

class SupportChatRepository {
  final Ref ref;
  SupportChatRepository(this.ref);

  Future<ChatSession> startSession({String language = 'english'}) async {
    final api = ref.read(apiClientProvider);
    final res = await api
        .post('/api/v1/support/sessions', data: {'language': language});
    return ChatSession.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ChatSession> getSession(String sessionId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/support/sessions/$sessionId');
    return ChatSession.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/support/sessions/$sessionId/messages');
    return (res.data as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// REST fallback for sending a message (used if the WebSocket isn't
  /// connected yet). Returns the newly created message(s).
  Future<List<ChatMessage>> sendMessageRest(
      String sessionId, String text) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/support/sessions/$sessionId/messages',
        data: {'text': text});
    return (res.data as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> escalate(String sessionId) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/support/sessions/$sessionId/escalate');
  }

  Future<void> closeSession(String sessionId) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/support/sessions/$sessionId/close');
  }

  /// Opens the live chat WebSocket. Caller owns the returned channel and
  /// must close it (e.g. in dispose()).
  WebSocketChannel connectWs(String sessionId) {
    final storage = ref.read(localStorageProvider);
    final base = storage.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final token = storage.accessToken ?? '';
    final uri = Uri.parse('$base/api/v1/support/ws/$sessionId?token=$token');
    return WebSocketChannel.connect(uri);
  }

  void sendOverWs(WebSocketChannel channel, String text) {
    channel.sink.add(jsonEncode({'text': text}));
  }
}

final supportChatRepositoryProvider =
    Provider((ref) => SupportChatRepository(ref));

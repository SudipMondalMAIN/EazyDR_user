enum ChatSender { user, bot, agent, system }

ChatSender chatSenderFromApi(String v) {
  switch (v) {
    case 'user':
      return ChatSender.user;
    case 'agent':
      return ChatSender.agent;
    case 'system':
      return ChatSender.system;
    case 'bot':
    default:
      return ChatSender.bot;
  }
}

class ChatMessage {
  final String id;
  final String sessionId;
  final ChatSender sender;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'].toString(),
        sessionId: j['session_id'].toString(),
        sender: chatSenderFromApi(j['sender_type'] as String),
        text: j['text'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  /// For messages that arrive over the WebSocket (slightly different, flat shape).
  factory ChatMessage.fromWsJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'].toString(),
        sessionId: j['session_id'].toString(),
        sender: chatSenderFromApi(j['sender_type'] as String),
        text: j['text'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

enum ChatSessionStatus { bot, waitingAgent, withAgent, closed }

ChatSessionStatus chatSessionStatusFromApi(String v) {
  switch (v) {
    case 'waiting_agent':
      return ChatSessionStatus.waitingAgent;
    case 'with_agent':
      return ChatSessionStatus.withAgent;
    case 'closed':
      return ChatSessionStatus.closed;
    case 'bot':
    default:
      return ChatSessionStatus.bot;
  }
}

class ChatSession {
  final String id;
  final ChatSessionStatus status;

  ChatSession({required this.id, required this.status});

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
        id: j['id'].toString(),
        status: chatSessionStatusFromApi(j['status'] as String),
      );
}

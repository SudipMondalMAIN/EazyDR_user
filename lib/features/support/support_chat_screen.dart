import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/core_providers.dart';
import '../../core/models/chat_message.dart';
import '../../core/repositories/support_chat_repository.dart';
import '../../core/theme/app_theme.dart';

const Map<String, String> _kLanguages = {
  'english': 'English',
  'hindi': 'हिन्दी',
  'bengali': 'বাংলা',
};

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Set<String> _seenIds = {};

  ChatSession? _session;
  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;
  bool _loading = true;
  bool _sending = false;
  ChatSessionStatus _status = ChatSessionStatus.bot;
  String _language = 'english';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Screen was off / app was backgrounded — the OS almost certainly
      // killed the socket. Refetch anything we missed and reconnect.
      _resumeSession();
    }
  }

  Future<void> _resumeSession() async {
    if (_session == null || _status == ChatSessionStatus.closed) return;
    final repo = ref.read(supportChatRepositoryProvider);
    try {
      final history = await repo.getMessages(_session!.id);
      _addAll(history);
    } catch (_) {
      // Ignore — we'll still try to reconnect the socket below.
    }
    _wsSub?.cancel();
    _ws?.sink.close();
    _connectWs(_session!.id);
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    final repo = ref.read(supportChatRepositoryProvider);
    final storage = ref.read(localStorageProvider);
    try {
      final savedId = storage.supportSessionId;
      ChatSession? session;
      if (savedId != null) {
        try {
          session = await repo.getSession(savedId);
        } catch (_) {
          // Saved session gone/invalid — fall through and start a new one.
          await storage.clearSupportSessionId();
        }
      }
      if (session == null) {
        session = await repo.startSession(language: _language);
        await storage.setSupportSessionId(session.id);
      } else if (session.status == ChatSessionStatus.closed) {
        // Previous conversation was closed — start a fresh one.
        session = await repo.startSession(language: _language);
        await storage.setSupportSessionId(session.id);
      }
      _session = session;
      _status = session.status;
      final history = await repo.getMessages(session.id);
      _addAll(history);
      _connectWs(session.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not start chat: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restartWithLanguage(String lang) async {
    final repo = ref.read(supportChatRepositoryProvider);
    final storage = ref.read(localStorageProvider);
    setState(() {
      _loading = true;
      _messages.clear();
      _seenIds.clear();
    });
    _wsSub?.cancel();
    _ws?.sink.close();
    try {
      final session = await repo.startSession(language: lang);
      await storage.setSupportSessionId(session.id);
      _session = session;
      _status = session.status;
      final history = await repo.getMessages(session.id);
      _addAll(history);
      _connectWs(session.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not start chat: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _connectWs(String sessionId) {
    final repo = ref.read(supportChatRepositoryProvider);
    try {
      _ws = repo.connectWs(sessionId);
      _wsSub = _ws!.stream.listen((event) {
        final data = jsonDecode(event as String) as Map<String, dynamic>;
        if (data['type'] == 'message') {
          _addAll([ChatMessage.fromWsJson(data)]);
        } else if (data['type'] == 'session_closed') {
          setState(() => _status = ChatSessionStatus.closed);
        }
      }, onError: (_) {
        // Live socket dropped — REST send fallback still works.
      });
    } catch (_) {
      // WebSocket unavailable — falls back to REST send silently.
    }
  }

  void _addAll(List<ChatMessage> msgs) {
    setState(() {
      for (final m in msgs) {
        if (_seenIds.add(m.id)) _messages.add(m);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _session == null || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    final repo = ref.read(supportChatRepositoryProvider);
    try {
      if (_ws != null) {
        repo.sendOverWs(_ws!, text);
      } else {
        final newMsgs = await repo.sendMessageRest(_session!.id, text);
        _addAll(newMsgs);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _talkToSupport() async {
    if (_session == null) return;
    final repo = ref.read(supportChatRepositoryProvider);
    try {
      await repo.escalate(_session!.id);
      setState(() => _status = ChatSessionStatus.waitingAgent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _endChat() async {
    if (_session == null || _status == ChatSessionStatus.closed) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End chat?'),
        content: const Text(
            'This will close the current conversation. You can always start a new chat later.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('End Chat')),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = ref.read(supportChatRepositoryProvider);
    final storage = ref.read(localStorageProvider);
    try {
      await repo.closeSession(_session!.id);
      setState(() => _status = ChatSessionStatus.closed);
      await storage.clearSupportSessionId();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wsSub?.cancel();
    _ws?.sink.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _statusLabel() {
    switch (_status) {
      case ChatSessionStatus.bot:
        return 'EazyDoctor Support Bot';
      case ChatSessionStatus.waitingAgent:
        return 'Waiting for a support agent…';
      case ChatSessionStatus.withAgent:
        return 'Connected to a support agent';
      case ChatSessionStatus.closed:
        return 'Chat ended';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canChat = _status != ChatSessionStatus.closed;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        actions: [
          if (_status != ChatSessionStatus.closed && _session != null)
            IconButton(
              tooltip: 'End Chat',
              icon: const Icon(Icons.close_rounded),
              onPressed: _endChat,
            ),
          PopupMenuButton<String>(
            initialValue: _language,
            tooltip: 'Language',
            icon: const Icon(Icons.language_rounded),
            onSelected: (lang) {
              if (lang == _language) return;
              setState(() => _language = lang);
              _restartWithLanguage(lang);
            },
            itemBuilder: (_) => _kLanguages.entries
                .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: context.tokens.surface2,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    _statusLabel(),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: context.tokens.text2),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) =>
                        _MessageBubble(message: _messages[i]),
                  ),
                ),
                if (_status == ChatSessionStatus.bot)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _talkToSupport,
                        icon: const Icon(Icons.headset_mic_rounded, size: 18),
                        label: const Text('Talk to Customer Support'),
                      ),
                    ),
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: canChat,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: canChat
                                  ? 'Type a message…'
                                  : 'This chat has ended',
                              filled: true,
                              fillColor: context.tokens.surface2,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: canChat && !_sending ? _send : null,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == ChatSender.user;
    final isSystem = message.sender == ChatSender.system;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: context.tokens.text3),
          ),
        ),
      );
    }

    final bg = isUser
        ? Theme.of(context).colorScheme.primary
        : context.tokens.surface2;
    final fg = isUser ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(message.text, style: TextStyle(color: fg)),
      ),
    );
  }
}

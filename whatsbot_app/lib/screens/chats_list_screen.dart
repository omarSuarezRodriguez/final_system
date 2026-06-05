import 'dart:async' show StreamSubscription, Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../models/conversation.dart';
import '../models/realtime_event.dart';
import '../main.dart';
import '../services/api_client.dart';
import '../services/message_alerts_service.dart';
import '../services/realtime_service.dart';
import '../theme/whatsapp_theme.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  List<Conversation> _conversations = [];
  bool _loading = true;
  String? _error;
  Timer? _fallbackTimer;
  StreamSubscription<RealtimeEvent>? _realtimeSub;
  StreamSubscription<bool>? _connectionSub;

  @override
  void initState() {
    super.initState();
    messageAlerts.onOpenConversation = _openConversationById;
    unawaited(realtimeService.connect());
    _realtimeSub = realtimeService.events.listen(_onRealtimeEvent);
    _connectionSub = realtimeService.connectionState.listen((_) {
      _configureFallbackTimer();
    });
    _load();
    _configureFallbackTimer();
  }

  @override
  void dispose() {
    messageAlerts.onOpenConversation = null;
    _realtimeSub?.cancel();
    _connectionSub?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _configureFallbackTimer() {
    _fallbackTimer?.cancel();
    if (realtimeService.isConnected) return;
    _fallbackTimer = Timer.periodic(ApiConfig.fallbackPollInterval, (_) {
      if (!realtimeService.isConnected) {
        _load(silent: true);
      }
    });
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case 'message.new':
        final message = event.message;
        final conversation = event.conversation;
        if (message != null && conversation != null) {
          _upsertConversation(conversation);
          unawaited(
            messageAlerts.handleRealtimeMessage(
              conversation: conversation,
              message: message,
            ),
          );
        } else if (conversation != null) {
          _upsertConversation(conversation);
        }
        break;
      case 'conversation.updated':
      case 'conversation.sync':
        final conversation = event.conversation;
        if (conversation != null) {
          _upsertConversation(conversation);
        }
        break;
    }
  }

  void _upsertConversation(Conversation conversation) {
    final index =
        _conversations.indexWhere((item) => item.id == conversation.id);
    setState(() {
      if (index >= 0) {
        _conversations[index] = conversation;
      } else {
        _conversations.add(conversation);
      }
      _sortConversations();
      _loading = false;
      _error = null;
    });
  }

  void _sortConversations() {
    _conversations.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.updatedAt;
      final bTime = b.lastMessageAt ?? b.updatedAt;
      return bTime.compareTo(aTime);
    });
  }

  Future<void> _openConversationById(int conversationId) async {
    Conversation? chat;
    for (final item in _conversations) {
      if (item.id == conversationId) {
        chat = item;
        break;
      }
    }
    if (chat == null) {
      await _load(silent: true);
      for (final item in _conversations) {
        if (item.id == conversationId) {
          chat = item;
          break;
        }
      }
    }
    if (chat == null || !mounted) return;

    final nav = navigatorKey.currentState;
    if (nav == null) return;
    await nav.push(
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: chat!)),
    );
    if (mounted) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await apiClient.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _loading = false;
      });
      _sortConversations();
      await messageAlerts.handleConversations(list);
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Sin conexión con la API';
        _loading = false;
      });
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return DateFormat('HH:mm').format(local);
    }
    return DateFormat('dd/MM').format(local);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(apiClient.businessName ?? 'WhatsBot'),
        actions: [
          if (!realtimeService.isConnected)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.cloud_off,
                size: 20,
                color: Colors.white70,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ajustes',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (mounted) _load(silent: true);
            },
          ),
        ],
      ),
      body: _loading && _conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _conversations.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'Aún no hay conversaciones.\n'
                                'Cuando un cliente escriba al bot, aparecerá aquí.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: WhatsAppTheme.subtitleGrey),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: _conversations.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            indent: 72,
                          ),
                          itemBuilder: (context, index) {
                            final chat = _conversations[index];
                            final unread =
                                messageAlerts.isConversationUnread(chat);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: WhatsAppTheme.accentGreen,
                                child: Text(
                                  chat.displayName.isNotEmpty
                                      ? chat.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                chat.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                chat.lastMessagePreview ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unread
                                      ? Colors.black87
                                      : WhatsAppTheme.subtitleGrey,
                                  fontWeight:
                                      unread ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTime(chat.lastMessageAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: unread
                                          ? WhatsAppTheme.accentGreen
                                          : WhatsAppTheme.subtitleGrey,
                                      fontWeight: unread
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (unread) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: WhatsAppTheme.accentGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(conversation: chat),
                                  ),
                                );
                                _load(silent: true);
                              },
                            );
                          },
                        ),
                ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../models/conversation.dart';
import '../main.dart';
import '../services/api_client.dart';
import '../services/message_alerts_service.dart';
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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    messageAlerts.onOpenConversation = _openConversationById;
    _load();
    _refreshTimer = Timer.periodic(ApiConfig.chatsRefreshInterval, (_) {
      _load(silent: true);
    });
  }

  @override
  void dispose() {
    messageAlerts.onOpenConversation = null;
    _refreshTimer?.cancel();
    super.dispose();
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

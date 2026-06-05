import 'dart:async' show StreamSubscription, Timer, unawaited;

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/order.dart';
import '../models/realtime_event.dart';
import '../services/api_client.dart';
import '../services/message_alerts_service.dart';
import '../services/realtime_service.dart';
import '../theme/whatsapp_theme.dart';
import '../widgets/message_bubble.dart';
import 'order_actions_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  PendingOrder? _pendingOrder;
  bool _loading = true;
  bool _sending = false;
  bool _orderBusy = false;
  Timer? _fallbackTimer;
  StreamSubscription<RealtimeEvent>? _realtimeSub;
  StreamSubscription<bool>? _connectionSub;

  @override
  void initState() {
    super.initState();
    messageAlerts.setActiveConversation(widget.conversation.id);
    _realtimeSub = realtimeService.events.listen(_onRealtimeEvent);
    _connectionSub = realtimeService.connectionState.listen((_) {
      _configureFallbackTimer();
    });
    _refresh();
    _configureFallbackTimer();
  }

  @override
  void dispose() {
    messageAlerts.setActiveConversation(null);
    _realtimeSub?.cancel();
    _connectionSub?.cancel();
    _fallbackTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _configureFallbackTimer() {
    _fallbackTimer?.cancel();
    if (realtimeService.isConnected) return;
    _fallbackTimer = Timer.periodic(ApiConfig.fallbackPollInterval, (_) {
      if (!realtimeService.isConnected) {
        _refresh(silent: true);
      }
    });
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (!mounted) return;

    if (event.type == 'message.new') {
      final message = event.message;
      if (message == null ||
          message.conversationId != widget.conversation.id) {
        return;
      }
      _appendMessage(message);
      unawaited(
        messageAlerts.handleChatMessages(
          conversationId: widget.conversation.id,
          displayName: widget.conversation.displayName,
          messages: _messages,
        ),
      );
    }
  }

  void _appendMessage(ChatMessage message) {
    if (_messages.any((item) => item.id == message.id)) return;
    setState(() {
      _messages = [..._messages, message];
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final afterId = _messages.isEmpty
          ? null
          : _messages.map((m) => m.id).reduce((a, b) => a > b ? a : b);
      final incremental = afterId != null && silent && _messages.isNotEmpty;
      final messages = incremental
          ? await apiClient.getMessages(
              widget.conversation.id,
              afterId: afterId,
            )
          : await apiClient.getMessages(widget.conversation.id);
      final orders = await apiClient.getPendingOrders();
      final wa = widget.conversation.customerWaId;
      PendingOrder? match;
      for (final o in orders) {
        if (_sameWa(o.waId, wa)) {
          match = o;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        if (incremental && messages.isNotEmpty) {
          final known = _messages.map((m) => m.id).toSet();
          _messages = [
            ..._messages,
            ...messages.where((m) => !known.contains(m.id)),
          ];
        } else {
          _messages = messages;
        }
        _pendingOrder = match;
        _loading = false;
      });
      await messageAlerts.handleChatMessages(
        conversationId: widget.conversation.id,
        displayName: widget.conversation.displayName,
        messages: _messages,
      );
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool _sameWa(String a, String b) {
    final na = a.replaceAll(RegExp(r'[^0-9+]'), '');
    final nb = b.replaceAll(RegExp(r'[^0-9+]'), '');
    return na == nb || na.endsWith(nb) || nb.endsWith(na);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _inputController.clear();
    try {
      final msg = await apiClient.sendMessage(
        customerWaId: widget.conversation.customerWaId,
        body: text,
      );
      if (!mounted) return;
      _appendMessage(msg);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _approveOrder() async {
    final order = _pendingOrder;
    if (order == null || _orderBusy) return;
    setState(() => _orderBusy = true);
    try {
      final msg = await apiClient.approveOrder(order.orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await _refresh(silent: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _orderBusy = false);
    }
  }

  Future<void> _rejectOrder() async {
    final order = _pendingOrder;
    if (order == null || _orderBusy) return;
    setState(() => _orderBusy = true);
    try {
      final msg = await apiClient.rejectOrder(order.orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await _refresh(silent: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _orderBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.displayName),
            Text(
              widget.conversation.customerWaId,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_pendingOrder != null)
            OrderActionsBar(
              order: _pendingOrder!,
              busy: _orderBusy,
              onApprove: _approveOrder,
              onReject: _rejectOrder,
            ),
          Expanded(
            child: Container(
              color: WhatsAppTheme.chatBackground,
              child: _loading && _messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => MessageBubble(message: _messages[i]),
                    ),
            ),
          ),
          Material(
            color: const Color(0xFFF0F0F0),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: InputDecoration(
                          hintText: 'Mensaje',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        maxLines: 4,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: WhatsAppTheme.accentGreen,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _sending ? null : _send,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

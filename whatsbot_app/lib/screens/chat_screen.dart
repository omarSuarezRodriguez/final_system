import 'dart:async';

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/order.dart';
import '../services/api_client.dart';
import '../services/message_alerts_service.dart';
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
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    messageAlerts.setActiveConversation(widget.conversation.id);
    _refresh();
    _pollTimer = Timer.periodic(ApiConfig.chatPollInterval, (_) {
      _refresh(silent: true);
    });
  }

  @override
  void dispose() {
    messageAlerts.setActiveConversation(null);
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final messages =
          await apiClient.getMessages(widget.conversation.id);
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
        _messages = messages;
        _pendingOrder = match;
        _loading = false;
      });
      await messageAlerts.handleChatMessages(
        conversationId: widget.conversation.id,
        displayName: widget.conversation.displayName,
        messages: messages,
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
      setState(() {
        _messages = [..._messages, msg];
      });
      _scrollToBottom();
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

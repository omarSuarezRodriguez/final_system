import 'conversation.dart';
import 'message.dart';

/// Evento JSON del WebSocket `/whatsbot/ws`.
class RealtimeEvent {
  RealtimeEvent({
    required this.type,
    this.message,
    this.conversation,
  });

  final String type;
  final ChatMessage? message;
  final Conversation? conversation;

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) {
    final msg = json['message'];
    final conv = json['conversation'];
    return RealtimeEvent(
      type: json['type'] as String? ?? 'unknown',
      message: msg is Map<String, dynamic>
          ? ChatMessage.fromJson(msg)
          : null,
      conversation: conv is Map<String, dynamic>
          ? Conversation.fromJson(conv)
          : null,
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.direction,
    required this.body,
    required this.waId,
    required this.isAdmin,
    required this.channel,
    required this.createdAt,
  });

  final int id;
  final int conversationId;
  final String direction;
  final String body;
  final String waId;
  final bool isAdmin;
  final String channel;
  final DateTime createdAt;

  bool get isOutgoing => direction == 'outgoing' || isAdmin;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      direction: json['direction'] as String,
      body: json['body'] as String,
      waId: json['wa_id'] as String,
      isAdmin: json['is_admin'] as bool? ?? false,
      channel: json['channel'] as String? ?? 'whatsapp',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

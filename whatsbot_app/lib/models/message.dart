class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.direction,
    required this.body,
    required this.waId,
    required this.isAdmin,
    required this.channel,
    required this.status,
    this.deliveredAt,
    this.readAt,
    required this.createdAt,
  });

  final int id;
  final int conversationId;
  final String direction;
  final String body;
  final String waId;
  final bool isAdmin;
  final String channel;
  final String status;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isOutgoing => direction == 'outgoing' || isAdmin;

  ChatMessage copyWith({
    String? status,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      direction: direction,
      body: body,
      waId: waId,
      isAdmin: isAdmin,
      channel: channel,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      direction: json['direction'] as String,
      body: json['body'] as String,
      waId: json['wa_id'] as String,
      isAdmin: json['is_admin'] as bool? ?? false,
      channel: json['channel'] as String? ?? 'whatsapp',
      status: json['status'] as String? ?? 'delivered',
      deliveredAt: _parseDate(json['delivered_at']),
      readAt: _parseDate(json['read_at']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}

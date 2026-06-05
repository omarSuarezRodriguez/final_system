class Conversation {
  Conversation({
    required this.id,
    required this.businessId,
    required this.customerWaId,
    this.customerName,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.updatedAt,
  });

  final int id;
  final String businessId;
  final String customerWaId;
  final String? customerName;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final DateTime updatedAt;

  String get displayName =>
      (customerName != null && customerName!.trim().isNotEmpty)
          ? customerName!
          : customerWaId;

  Conversation copyWith({
    String? customerName,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id,
      businessId: businessId,
      customerWaId: customerWaId,
      customerName: customerName ?? this.customerName,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      businessId: json['business_id'] as String,
      customerWaId: json['customer_wa_id'] as String,
      customerName: json['customer_name'] as String?,
      lastMessagePreview: json['last_message_preview'] as String?,
      lastMessageAt: _parseDate(json['last_message_at']),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsbot_app/data/local/app_database.dart';
import 'package:whatsbot_app/data/repositories/chat_repository.dart';
import 'package:whatsbot_app/data/repositories/message_repository.dart';
import 'package:whatsbot_app/data/sync/sync_engine.dart';
import 'package:whatsbot_app/models/conversation.dart';
import 'package:whatsbot_app/models/message.dart';
import 'package:whatsbot_app/models/realtime_event.dart';

import '../helpers/test_api_client.dart';

void main() {
  late AppDatabase db;
  late TestApiClient testApi;
  late ChatRepository chats;
  late MessageRepository messages;
  late SyncEngine engine;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    testApi = TestApiClient();
    await testApi.login();
    chats = ChatRepository(db, testApi.client);
    messages = MessageRepository(db, testApi.client);
    engine = SyncEngine(chats, messages);

    await chats.upsertConversation(
      Conversation(
        id: 1,
        businessId: 'default',
        customerWaId: '+5491111111111',
        updatedAt: DateTime.utc(2026, 6, 1, 10),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('handleRealtimeEvent persiste message.new en SQLite', () async {
    final event = RealtimeEvent(
      type: 'message.new',
      message: ChatMessage(
        id: 77,
        conversationId: 1,
        direction: 'incoming',
        body: 'Desde WS',
        waId: '+5491111111111',
        isAdmin: false,
        channel: 'whatsapp',
        status: 'delivered',
        createdAt: DateTime.utc(2026, 6, 1, 12),
      ),
      conversation: Conversation(
        id: 1,
        businessId: 'default',
        customerWaId: '+5491111111111',
        lastMessagePreview: 'Desde WS',
        lastMessageAt: DateTime.utc(2026, 6, 1, 12),
        updatedAt: DateTime.utc(2026, 6, 1, 12),
      ),
    );

    await engine.handleRealtimeEvent(event);

    final stored = await messages.watchMessages(1).first;
    expect(stored.single.id, 77);
    expect(stored.single.body, 'Desde WS');

    final conversation = await chats.getConversation(1);
    expect(conversation?.lastMessagePreview, 'Desde WS');
  });

  test('handleRealtimeEvent actualiza conversación aunque el mensaje esté deduplicado',
      () async {
    final message = ChatMessage(
      id: 88,
      conversationId: 1,
      direction: 'incoming',
      body: 'Cliente escribe',
      waId: '+5491111111111',
      isAdmin: false,
      channel: 'whatsapp',
      status: 'delivered',
      createdAt: DateTime.utc(2026, 6, 1, 15),
    );
    await messages.upsertMessage(message);

    await chats.upsertConversation(
      Conversation(
        id: 1,
        businessId: 'default',
        customerWaId: '+5491111111111',
        lastMessagePreview: 'Viejo',
        lastMessageAt: DateTime.utc(2026, 6, 1, 10),
        updatedAt: DateTime.utc(2026, 6, 1, 10),
      ),
    );

    await engine.handleRealtimeEvent(
      RealtimeEvent(
        type: 'message.new',
        message: message,
        conversation: Conversation(
          id: 1,
          businessId: 'default',
          customerWaId: '+5491111111111',
          lastMessagePreview: 'Cliente escribe',
          lastMessageAt: DateTime.utc(2026, 6, 1, 15),
          updatedAt: DateTime.utc(2026, 6, 1, 15),
        ),
      ),
    );

    final conversation = await chats.getConversation(1);
    expect(conversation?.lastMessageAt?.toUtc(), DateTime.utc(2026, 6, 1, 15));
    expect(conversation?.lastMessagePreview, 'Cliente escribe');
  });

  test('syncMessagesIncremental omite sync si caché reciente', () async {
    testApi.messagesByConversation[1] = [
      {
        'id': 10,
        'conversation_id': 1,
        'direction': 'incoming',
        'body': 'Cacheado',
        'wa_id': '+5491111111111',
        'is_admin': false,
        'channel': 'whatsapp',
        'status': 'delivered',
        'created_at': DateTime.utc(2026, 6, 1, 11).toIso8601String(),
      },
    ];
    await messages.refreshFromApi(1, incremental: true);
    testApi.messagesByConversation[1] = [
      {
        'id': 11,
        'conversation_id': 1,
        'direction': 'incoming',
        'body': 'Nuevo',
        'wa_id': '+5491111111111',
        'is_admin': false,
        'channel': 'whatsapp',
        'status': 'delivered',
        'created_at': DateTime.utc(2026, 6, 1, 12).toIso8601String(),
      },
    ];

    final skipped = await engine.syncMessagesIncremental(1);
    expect(skipped, isEmpty);

    final stored = await messages.watchMessages(1).first;
    expect(stored, hasLength(1));
    expect(stored.single.id, 10);
  });

  test('syncOnReconnect vacía cola saliente pendiente', () async {
    testApi.failSend = true;
    await messages.sendMessage(
      conversationId: 1,
      customerWaId: '+5491111111111',
      body: 'Cola',
    );

    testApi.failSend = false;
    engine.trackOpenConversation(1);
    await engine.syncOnReconnect();

    final pending = await db.outboundQueueDao.listPending();
    expect(pending, isEmpty);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsbot_app/di/app_services.dart';
import 'package:whatsbot_app/models/conversation.dart';
import 'package:whatsbot_app/screens/chats_list_screen.dart';

import '../helpers/test_app_services.dart';

void main() {
  setUp(() async {
    await setUpTestAppServices();
  });

  tearDown(() async {
    await tearDownTestAppServices();
  });

  testWidgets('ChatsListScreen muestra estado vacío sin conversaciones', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChatsListScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.textContaining('Aún no hay conversaciones'),
      findsOneWidget,
    );

    await disposeWidgetTree(tester);
  });

  testWidgets('ChatsListScreen ordena conversaciones por lastMessageAt descendente', (
    WidgetTester tester,
  ) async {
    final chats = AppServices.chatRepository;
    await chats.upsertConversation(
      Conversation(
        id: 1,
        businessId: 'default',
        customerWaId: '+5491111111001',
        customerName: 'Chat viejo',
        lastMessagePreview: 'Antiguo',
        lastMessageAt: DateTime.utc(2026, 6, 5, 9),
        updatedAt: DateTime.utc(2026, 6, 5, 9),
      ),
    );
    await chats.upsertConversation(
      Conversation(
        id: 2,
        businessId: 'default',
        customerWaId: '+5491111111002',
        customerName: 'Chat reciente',
        lastMessagePreview: 'Último',
        lastMessageAt: DateTime.utc(2026, 6, 5, 12),
        updatedAt: DateTime.utc(2026, 6, 5, 12),
      ),
    );
    await chats.upsertConversation(
      Conversation(
        id: 3,
        businessId: 'default',
        customerWaId: '+5491111111003',
        customerName: 'Chat medio',
        lastMessagePreview: 'Medio',
        lastMessageAt: DateTime.utc(2026, 6, 5, 10),
        updatedAt: DateTime.utc(2026, 6, 5, 10),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ChatsListScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Chat reciente'), findsOneWidget);
    expect(find.text('Chat medio'), findsOneWidget);
    expect(find.text('Chat viejo'), findsOneWidget);

    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title as Text).data)
        .toList();

    expect(titles, ['Chat reciente', 'Chat medio', 'Chat viejo']);

    await disposeWidgetTree(tester);
  });
}

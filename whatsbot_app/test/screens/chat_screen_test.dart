import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsbot_app/di/app_services.dart';
import 'package:whatsbot_app/models/conversation.dart';
import 'package:whatsbot_app/models/message.dart';
import 'package:whatsbot_app/screens/chat_screen.dart';

import '../helpers/test_app_services.dart';

void main() {
  setUp(() async {
    await setUpTestAppServices();
  });

  tearDown(() async {
    await tearDownTestAppServices();
  });

  Conversation conversation() {
    return Conversation(
      id: 1,
      businessId: 'default',
      customerWaId: '+5491111111111',
      customerName: 'Omar Suarez',
      updatedAt: DateTime.utc(2026, 6, 5, 10),
    );
  }

  testWidgets('ChatScreen muestra mensajes desde SQLite', (
    WidgetTester tester,
  ) async {
    final messages = [
      ChatMessage(
        id: 1,
        conversationId: 1,
        direction: 'incoming',
        body: 'Hola desde el cliente',
        waId: '+5491111111111',
        isAdmin: false,
        channel: 'whatsapp',
        status: 'delivered',
        createdAt: DateTime.utc(2026, 6, 5, 10, 28),
      ),
      ChatMessage(
        id: 2,
        conversationId: 1,
        direction: 'outgoing',
        body: 'Respuesta del admin',
        waId: '+5491111111111',
        isAdmin: true,
        channel: 'whatsapp',
        status: 'sent',
        createdAt: DateTime.utc(2026, 6, 5, 10, 29),
      ),
    ];
    for (final message in messages) {
      await AppServices.messageRepository.upsertMessage(message);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          conversation: conversation(),
          initialMessages: messages,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Hola desde el cliente'), findsOneWidget);
    expect(find.text('Respuesta del admin'), findsOneWidget);
    expect(find.text('Omar Suarez'), findsOneWidget);

    await disposeWidgetTree(tester);
  });

  testWidgets('ChatScreen muestra burbuja al enviar mensaje como admin', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          conversation: conversation(),
          initialMessages: const [],
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Mensaje de prueba');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mensaje de prueba'), findsOneWidget);

    await disposeWidgetTree(tester);
  });

  testWidgets('ChatScreen muestra mensaje admin tras confirmación en SQLite', (
    WidgetTester tester,
  ) async {
    await AppServices.messageRepository.upsertMessage(
      ChatMessage(
        id: 42,
        conversationId: 1,
        direction: 'outgoing',
        body: 'Admin confirmado',
        waId: '+5491111111111',
        isAdmin: true,
        channel: 'whatsapp',
        status: 'sent',
        createdAt: DateTime.utc(2026, 6, 5, 11),
        clientUuid: 'uuid-admin-confirmado',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          conversation: conversation(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Admin confirmado'), findsOneWidget);

    await disposeWidgetTree(tester);
  });
}

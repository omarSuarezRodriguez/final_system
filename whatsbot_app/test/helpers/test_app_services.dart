import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsbot_app/data/local/app_database.dart';
import 'package:whatsbot_app/data/repositories/chat_repository.dart';
import 'package:whatsbot_app/data/repositories/message_repository.dart';
import 'package:whatsbot_app/data/sync/sync_engine.dart';
import 'package:whatsbot_app/di/app_services.dart';
import 'package:whatsbot_app/services/realtime_service.dart';

import 'test_api_client.dart';

/// Arranca AppServices con SQLite en memoria y API mock para widget tests.
Future<TestApiClient> setUpTestAppServices() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final testApi = TestApiClient();
  await testApi.login();

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  AppServices.database = db;
  AppServices.chatRepository = ChatRepository(db, testApi.client);
  AppServices.messageRepository = MessageRepository(db, testApi.client);
  AppServices.syncEngine = SyncEngine(
    AppServices.chatRepository,
    AppServices.messageRepository,
  );
  realtimeService.onReconnectSync = AppServices.syncEngine.syncOnReconnect;
  realtimeService.persistEvent = AppServices.syncEngine.handleRealtimeEvent;

  await realtimeService.disconnect();
  return testApi;
}

Future<void> tearDownTestAppServices() async {
  await realtimeService.disconnect();
  await AppServices.database.close();
}

/// Cierra pantallas y drena timers de Drift/WS antes del dispose del test.
Future<void> disposeWidgetTree(WidgetTester tester) async {
  await realtimeService.disconnect();
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

import 'dart:async' show Timer, unawaited;

import '../data/local/app_database.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/message_repository.dart';
import '../data/sync/sync_engine.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/api_client.dart';
import '../services/connectivity_service.dart';
import '../services/message_alerts_service.dart';
import '../services/realtime_service.dart';

/// Inicialización de DB local, repositorios y motor de sync (OF-A / OF-B / OF-D).
class AppServices {
  AppServices._();

  static late AppDatabase database;
  static late ChatRepository chatRepository;
  static late MessageRepository messageRepository;
  static late SyncEngine syncEngine;

  static bool _initialized = false;
  static Timer? _foregroundSyncTimer;

  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;
    database = AppDatabase();
    chatRepository = ChatRepository(database, apiClient);
    messageRepository = MessageRepository(database, apiClient);
    syncEngine = SyncEngine(chatRepository, messageRepository);
    _wireRealtime();
    _wireConnectivity();
    await connectivityService.start();
    _initialized = true;
  }

  static void _wireRealtime() {
    realtimeService.onReconnectSync = syncEngine.syncOnReconnect;
    realtimeService.persistEvent = syncEngine.handleRealtimeEvent;
    realtimeService.connectivityOnline = () => connectivityService.isOnline;
    syncEngine.onIncomingMessage = _onIncomingMessage;
  }

  static Future<void> _onIncomingMessage(
    Conversation conversation,
    ChatMessage message,
  ) {
    return messageAlerts.handleRealtimeMessage(
      conversation: conversation,
      message: message,
    );
  }

  static void _wireConnectivity() {
    connectivityService.onBackOnline = _onBackOnline;
  }

  static Future<void> _onBackOnline() async {
    if (!apiClient.isLoggedIn) return;
    await startRealtimeSession();
  }

  static Future<void> clearLocalData() async {
    if (!_initialized) return;
    await database.clearAll();
  }

  /// Login / cold start: WS + hidratación + keepalive (sesión WhatsApp).
  static Future<void> startRealtimeSession() async {
    if (!_initialized || !apiClient.isLoggedIn) return;
    await realtimeService.connect();
    await hydrateAfterLogin();
    _startForegroundFallback();
  }

  /// Vuelta a primer plano: reconectar WS y traer delta.
  static Future<void> onAppResumed() async {
    if (!_initialized || !apiClient.isLoggedIn) return;
    await realtimeService.onAppResumed();
    _startForegroundFallback();
  }

  /// Cola saliente + sync incremental (también tras reconexión WS).
  static Future<void> hydrateAfterLogin() async {
    if (!_initialized) return;
    await syncEngine.syncOnReconnect();
  }

  /// Reintenta WS cada 90s si se cayó con la app abierta.
  static void _startForegroundFallback() {
    _foregroundSyncTimer?.cancel();
    _foregroundSyncTimer = Timer.periodic(
      const Duration(seconds: 90),
      (_) => unawaited(_foregroundSyncTick()),
    );
  }

  static Future<void> _foregroundSyncTick() async {
    if (!apiClient.isLoggedIn || !connectivityService.isOnline) return;
    if (realtimeService.isConnected) return;
    await realtimeService.ensureConnected();
  }

  static void stopForegroundFallback() {
    _foregroundSyncTimer?.cancel();
    _foregroundSyncTimer = null;
  }
}

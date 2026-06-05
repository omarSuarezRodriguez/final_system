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
  static bool _hydratedThisSession = false;

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
    realtimeService.shouldSyncOnConnect = () => !_hydratedThisSession;
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
    _hydratedThisSession = false;
    await database.clearAll();
  }

  /// Login / cold start: REST hidrata caché + WS para vivo (sin polling).
  static Future<void> startRealtimeSession() async {
    if (!_initialized || !apiClient.isLoggedIn) return;

    // 1) Caché local desde REST (como WhatsApp al abrir la app)
    await hydrateAfterLogin();

    // 2) Socket en paralelo; si `connected` llega tarde, syncGap lo cubre
    await realtimeService.connect();
    await realtimeService.waitUntilConnected();
  }

  /// Vuelta a primer plano: reconectar WS + delta REST una vez.
  static Future<void> onAppResumed() async {
    if (!_initialized || !apiClient.isLoggedIn) return;
    await realtimeService.onAppResumed();
  }

  /// Cola saliente + sync incremental (una vez por sesión en login).
  static Future<void> hydrateAfterLogin() async {
    if (!_initialized) return;
    await syncEngine.syncOnReconnect();
    realtimeService.markSyncCompleted();
    _hydratedThisSession = true;
  }

  static void resetSessionFlags() {
    _hydratedThisSession = false;
  }

  static void stopForegroundFallback() {}
}

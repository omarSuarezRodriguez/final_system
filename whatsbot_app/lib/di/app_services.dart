import '../data/local/app_database.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/message_repository.dart';
import '../data/sync/sync_engine.dart';
import '../services/api_client.dart';
import '../services/connectivity_service.dart';
import '../services/realtime_service.dart';

/// Inicialización de DB local, repositorios y motor de sync (OF-A / OF-B / OF-D).
class AppServices {
  AppServices._();

  static late AppDatabase database;
  static late ChatRepository chatRepository;
  static late MessageRepository messageRepository;
  static late SyncEngine syncEngine;

  static bool _initialized = false;

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
  }

  static void _wireConnectivity() {
    connectivityService.onBackOnline = _onBackOnline;
  }

  static Future<void> _onBackOnline() async {
    if (!apiClient.isLoggedIn) return;
    await hydrateAfterLogin();
    await realtimeService.connect();
  }

  static Future<void> clearLocalData() async {
    if (!_initialized) return;
    await database.clearAll();
  }

  /// Cola saliente + hidratación tras login, cold start o vuelta de red.
  static Future<void> hydrateAfterLogin() async {
    if (!_initialized) return;
    await syncEngine.syncOnReconnect();
  }
}

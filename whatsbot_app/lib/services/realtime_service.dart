import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../config/api_config.dart';
import '../models/realtime_event.dart';
import 'api_client.dart';

/// WebSocket tiempo real — Fase 11.3 + OF-B (persistencia vía SyncEngine).
///
/// Conecta tras login; reconexión con backoff; sync REST al reconectar.
class RealtimeService {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();

  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();
  final StreamController<bool> _connectionState =
      StreamController<bool>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;

  bool _intentionalDisconnect = false;
  bool _connecting = false;
  bool _connected = false;
  int _backoffSeconds = 1;

  /// Evita abrir WebSocket real en widget tests.
  bool disableSocketForTesting = false;

  /// Sync incremental al reconectar (delegado a SyncEngine).
  Future<void> Function()? onReconnectSync;

  /// Persiste evento WS en SQLite antes de emitirlo a la UI.
  Future<void> Function(RealtimeEvent event)? persistEvent;

  Stream<RealtimeEvent> get events => _events.stream;

  Stream<bool> get connectionState => _connectionState.stream;

  bool get isConnected => _connected;

  Future<void> connect() async {
    if (!apiClient.isLoggedIn || disableSocketForTesting) return;
    _intentionalDisconnect = false;
    _reconnectTimer?.cancel();
    await _openSocket();
  }

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _channel?.sink.close(ws_status.goingAway);
    } catch (_) {}
    _channel = null;
    _setConnected(false);
  }

  Future<void> syncNow() async {
    await _syncAfterReconnect();
  }

  void sendTyping({required int conversationId, required bool isTyping}) {
    _sendJson({
      'type': isTyping ? 'typing.start' : 'typing.stop',
      'conversation_id': conversationId,
    });
  }

  Future<void> _openSocket() async {
    if (_connecting || _intentionalDisconnect || !apiClient.isLoggedIn) {
      return;
    }

    final token = apiClient.accessToken;
    if (token == null || token.isEmpty) return;

    _connecting = true;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _channel?.sink.close(ws_status.goingAway);
    } catch (_) {}
    _channel = null;
    _setConnected(false);

    try {
      final uri = Uri.parse(
        '${ApiConfig.wsBaseUrl}/whatsbot/ws?token=${Uri.encodeComponent(token)}',
      );
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _subscription = channel.stream.listen(
        _onData,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _connecting = false;
      _scheduleReconnect();
    }
  }

  void _onData(dynamic data) {
    Map<String, dynamic>? map;
    try {
      final decoded = jsonDecode(data as String);
      if (decoded is Map<String, dynamic>) {
        map = decoded;
      } else if (decoded is Map) {
        map = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return;
    }
    if (map == null) return;

    final type = map['type'] as String? ?? '';
    if (type == 'ping') {
      _sendJson({'type': 'pong'});
      return;
    }
    if (type == 'connected') {
      _connecting = false;
      _backoffSeconds = 1;
      _setConnected(true);
      unawaited(_syncAfterReconnect());
      return;
    }
    if (type == 'pong') {
      return;
    }

    final event = RealtimeEvent.fromJson(map);
    _emitAfterPersist(event);
  }

  void _emitAfterPersist(RealtimeEvent event) {
    unawaited(emitAfterPersist(event));
  }

  /// Persiste en SQLite (si hay handler) y emite a listeners de UI.
  Future<void> emitAfterPersist(RealtimeEvent event) async {
    final persist = persistEvent;
    if (persist == null) {
      if (!_events.isClosed) _events.add(event);
      return;
    }

    try {
      await persist(event);
    } catch (_) {
      // Igual que producción: la UI recibe el evento aunque falle SQLite.
    }
    if (!_events.isClosed) _events.add(event);
  }

  /// Emula un frame WS en tests (misma ruta que `_onData`).
  Future<void> debugEmitEvent(RealtimeEvent event) => emitAfterPersist(event);

  void _handleDisconnect() {
    _connecting = false;
    _setConnected(false);
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect || !apiClient.isLoggedIn) return;
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: _backoffSeconds);
    _backoffSeconds = (_backoffSeconds * 2).clamp(1, 30);
    _reconnectTimer = Timer(delay, () {
      unawaited(_openSocket());
    });
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    _connectionState.add(value);
  }

  void _sendJson(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> _syncAfterReconnect() async {
    final sync = onReconnectSync;
    if (sync == null) return;
    try {
      await sync();
    } catch (_) {
      // Sync silencioso; el fallback REST reintentará.
    }
  }
}

final realtimeService = RealtimeService.instance;

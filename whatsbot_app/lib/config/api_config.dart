/// URL pública del backend — migrada de `API_PUBLIC_URL` en `final_system/.env`.
///
/// Valor actual en .env: `https://snowman-shower-pellet.ngrok-free.dev`
/// Emulador en la misma PC: puedes usar `http://127.0.0.1:5000` o esta URL ngrok.
/// Teléfono físico: usa la URL ngrok HTTPS (misma que Twilio webhook).
class ApiConfig {
  ApiConfig._();

  static const String apiBaseUrl =
      'https://snowman-shower-pellet.ngrok-free.dev';

  /// Fallback REST si el WebSocket no está conectado (reconexión).
  static const Duration fallbackPollInterval = Duration(seconds: 30);

  /// URL WebSocket derivada de [apiBaseUrl].
  static String get wsBaseUrl {
    final base = apiBaseUrl;
    if (base.startsWith('https://')) {
      return 'wss://${base.substring(8)}';
    }
    if (base.startsWith('http://')) {
      return 'ws://${base.substring(7)}';
    }
    return base;
  }
}

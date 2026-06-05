/// URL pública del backend — migrada de `API_PUBLIC_URL` en `final_system/.env`.
///
/// Valor actual en .env: `https://snowman-shower-pellet.ngrok-free.dev`
/// Emulador en la misma PC: puedes usar `http://127.0.0.1:5000` o esta URL ngrok.
/// Teléfono físico: usa la URL ngrok HTTPS (misma que Twilio webhook).
class ApiConfig {
  ApiConfig._();

  static const String apiBaseUrl =
      'https://snowman-shower-pellet.ngrok-free.dev';

  static const Duration chatPollInterval = Duration(seconds: 4);
  static const Duration chatsRefreshInterval = Duration(seconds: 8);
}

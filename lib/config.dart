/// URL base del backend.
///
/// Configurable en compile-time:
///   flutter run --dart-define=API_URL=https://mi-backend.railway.app/api
///
/// Valores por defecto según plataforma (se cambia en lib/config.dart):
///   Android emulador → 10.0.2.2 mapea al localhost del host
///   iOS simulator    → localhost
///   Dispositivo real → IP local de tu máquina (ej. 192.168.1.x)
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  /// Timeout para peticiones de red (segundos)
  static const int connectTimeoutSec = 10;
  static const int receiveTimeoutSec = 10;

  /// Intervalo de polling en VotingScreen
  static const int pollingIntervalSec = 3;
}

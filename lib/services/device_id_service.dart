import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Gestiona el identificador único del dispositivo.
///
/// El ID se genera una sola vez (UUID v4) y se persiste en SharedPreferences.
/// Se envía en cada voto para el control anti-duplicado del backend
/// (constraint @@unique([songId, deviceId]) en la tabla Vote).
class DeviceIdService {
  static const _key = 'mp_device_id';
  static const _uuid = Uuid();

  /// Cache en memoria — evita N llamadas a SharedPreferences por sesión.
  static String? _cached;

  /// Retorna el deviceId, creándolo y guardándolo si no existe.
  static Future<String> getDeviceId() async {
    if (_cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_key);

    if (id == null) {
      id = _uuid.v4();
      await prefs.setString(_key, id);
    }

    _cached = id;
    return id;
  }
}

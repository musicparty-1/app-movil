import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Resultado de la solicitud de permisos/posición.
sealed class GeoResult {}

class GeoPosition extends GeoResult {
  final double lat;
  final double lng;
  GeoPosition(this.lat, this.lng);
}

class GeoUnavailable extends GeoResult {
  final String reason;
  GeoUnavailable(this.reason);
}

/// Obtiene la posición actual del usuario.
/// Solicita permiso si no lo tiene. Devuelve [GeoUnavailable] en lugar de
/// lanzar excepción para no bloquear la UI.
Future<GeoResult> getUserPosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return GeoUnavailable('Servicios de ubicación desactivados');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return GeoUnavailable('Permiso de ubicación denegado');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return GeoUnavailable('Permiso de ubicación denegado permanentemente');
  }

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 8),
    ),
  );
  return GeoPosition(pos.latitude, pos.longitude);
}

/// Calcula la distancia en metros entre dos coordenadas (Haversine).
double haversineMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const r = 6371000.0; // radio de la Tierra en metros
  final phi1 = lat1 * math.pi / 180;
  final phi2 = lat2 * math.pi / 180;
  final dPhi = (lat2 - lat1) * math.pi / 180;
  final dLambda = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) *
          math.cos(phi2) *
          math.sin(dLambda / 2) *
          math.sin(dLambda / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Formatea una distancia en metros de forma legible.
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// Provider que obtiene la posición al montar la HomeScreen.
/// autoDispose para no retener permisos/recursos innecesariamente.
final userPositionProvider = FutureProvider.autoDispose<GeoResult>(
  (_) => getUserPosition(),
);

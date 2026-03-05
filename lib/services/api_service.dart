import 'package:dio/dio.dart';

import '../config.dart';
import '../models/event_model.dart';
import '../models/search_result_model.dart';

/// Servicio centralizado de llamadas HTTP al backend MusicParty.
/// Todas las peticiones son públicas — sin JWT ni autenticación.
class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout:
            const Duration(seconds: AppConfig.connectTimeoutSec),
        receiveTimeout:
            const Duration(seconds: AppConfig.receiveTimeoutSec),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  // ─── Eventos ──────────────────────────────────────────────────────────────

  /// GET /eventos/publico — lista todos los eventos en estado 'live'.
  Future<List<EventModel>> getPublicEvents() async {
    final response = await _dio.get<List>('/eventos/publico');
    return (response.data ?? [])
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /eventos/:id — detalle del evento con canciones y votos.
  Future<EventModel> getEvent(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/eventos/$id');
    return EventModel.fromJson(response.data!);
  }

  // ─── Votos ────────────────────────────────────────────────────────────────

  /// POST /votar — emite un voto.
  /// Lanza DioException con status 409 si el deviceId ya votó por esta canción.
  Future<Map<String, dynamic>> vote({
    required String songId,
    required String eventId,
    required String deviceId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/votar',
      data: {
        'songId': songId,
        'eventId': eventId,
        'deviceId': deviceId,
      },
    );
    return response.data ?? {};
  }

  // ─── Canciones ────────────────────────────────────────────────────────────

  /// GET /canciones/buscar?q= — busca en iTunes + Spotify.
  /// Devuelve lista vacía si query < 2 caracteres (el backend también lo hace).
  Future<List<SearchResultModel>> searchSongs(String query) async {
    final response = await _dio.get<List>(
      '/canciones/buscar',
      queryParameters: {'q': query.trim()},
    );
    return (response.data ?? [])
        .map((e) => SearchResultModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /canciones/sugerir-publico — el público sugiere una canción.
  Future<void> suggestSong({
    required String title,
    required String artist,
    required String eventId,
    String? coverUrl,
    String? spotifyId,
    String? suggestedBy,
  }) async {
    await _dio.post<void>(
      '/canciones/sugerir-publico',
      data: {
        'title': title,
        'artist': artist,
        'eventId': eventId,
        if (coverUrl != null && coverUrl.isNotEmpty) 'coverUrl': coverUrl,
        if (spotifyId != null && spotifyId.isNotEmpty) 'spotifyId': spotifyId,
        if (suggestedBy != null && suggestedBy.isNotEmpty)
          'suggestedBy': suggestedBy,
      },
    );
  }
}

/// Convierte un [DioException] en un mensaje legible para el usuario.
String dioErrorToMessage(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    case DioExceptionType.connectionError:
      return 'Sin conexión a internet.';
    case DioExceptionType.badResponse:
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is String) return msg;
        if (msg is List && msg.isNotEmpty) return msg.first as String;
      }
      return 'Error del servidor (${e.response?.statusCode}).';
    default:
      return 'Error inesperado. Intenta de nuevo.';
  }
}

import 'song_model.dart';

/// Evento público retornado por GET /eventos/publico
/// y GET /eventos/:id (este último incluye la lista de canciones).
class EventModel {
  final String id;
  final String name;
  final String venue;

  /// 'draft' | 'live' | 'finished'
  final String status;
  final DateTime createdAt;

  /// Solo presente en el detalle GET /eventos/:id
  final List<SongModel>? songs;

  /// 'club' | 'wedding' | 'private' | 'festival' | 'corporate' | 'other' | null
  final String? eventType;

  final bool allowAudienceSuggestions;

  /// Coordenadas del venue (opcionales — requieren que el DJ las haya configurado)
  final double? latitude;
  final double? longitude;

  /// Fecha estimada del evento (solo en eventos planificados / draft con scheduledAt)
  final DateTime? scheduledAt;

  const EventModel({
    required this.id,
    required this.name,
    required this.venue,
    required this.status,
    required this.createdAt,
    this.eventType,
    this.songs,
    this.allowAudienceSuggestions = true,
    this.latitude,
    this.longitude,
    this.scheduledAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      name: json['name'] as String,
      venue: json['venue'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      eventType: json['eventType'] as String?,
      allowAudienceSuggestions:
          json['allowAudienceSuggestions'] as bool? ?? true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
      songs: json['songs'] != null
          ? (json['songs'] as List)
              .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

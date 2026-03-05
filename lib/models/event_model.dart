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

  final bool allowAudienceSuggestions;

  const EventModel({
    required this.id,
    required this.name,
    required this.venue,
    required this.status,
    required this.createdAt,
    this.songs,
    this.allowAudienceSuggestions = true,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      name: json['name'] as String,
      venue: json['venue'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      allowAudienceSuggestions:
          json['allowAudienceSuggestions'] as bool? ?? true,
      songs: json['songs'] != null
          ? (json['songs'] as List)
              .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

/// Canción perteneciente a un evento.
///
/// El backend devuelve: GET /eventos/:id → songs: [ { ...campos, votes: Vote[] } ]
/// El voteCount se calcula como votes.length al deserializar.
class SongModel {
  final String id;
  final String title;
  final String artist;

  /// 'pending' | 'played'
  final String status;

  /// 'dj' | 'audience'
  final String addedBy;

  final int orderIndex;
  final String eventId;

  /// Número de votos — calculado de votes.length al parsear el JSON
  final int voteCount;

  final DateTime createdAt;

  // Metadatos opcionales (enriquecidos async por Spotify)
  final String? coverUrl;
  final double? bpm;
  final int? songKey; // 0-11 (Camelot wheel)
  final int? songMode; // 0=menor, 1=mayor
  final double? energy; // 0.0–1.0
  final double? danceability; // 0.0–1.0
  final String? suggestedBy; // Apodo del asistente

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.status,
    required this.addedBy,
    required this.orderIndex,
    required this.eventId,
    required this.voteCount,
    required this.createdAt,
    this.coverUrl,
    this.bpm,
    this.songKey,
    this.songMode,
    this.energy,
    this.danceability,
    this.suggestedBy,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    final votes = (json['votes'] as List?) ?? [];
    return SongModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      status: json['status'] as String,
      addedBy: json['addedBy'] as String? ?? 'dj',
      orderIndex: json['orderIndex'] as int? ?? 0,
      eventId: json['eventId'] as String,
      voteCount: votes.length,
      createdAt: DateTime.parse(json['createdAt'] as String),
      coverUrl: json['coverUrl'] as String?,
      bpm: (json['bpm'] as num?)?.toDouble(),
      songKey: json['songKey'] as int?,
      songMode: json['songMode'] as int?,
      energy: (json['energy'] as num?)?.toDouble(),
      danceability: (json['danceability'] as num?)?.toDouble(),
      suggestedBy: json['suggestedBy'] as String?,
    );
  }
}

/// Resultado de búsqueda de canciones — retornado por GET /canciones/buscar?q=
/// Procede de iTunes y/o Spotify (campo source).
class SearchResultModel {
  final String title;
  final String artist;
  final String? album;
  final String? coverUrl;
  final String? spotifyId;

  /// 'itunes' | 'spotify'
  final String source;

  const SearchResultModel({
    required this.title,
    required this.artist,
    this.album,
    this.coverUrl,
    this.spotifyId,
    required this.source,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      title: json['title'] as String? ?? 'Desconocido',
      artist: json['artist'] as String? ?? 'Desconocido',
      album: json['album'] as String?,
      coverUrl: json['coverUrl'] as String?,
      spotifyId: json['spotifyId'] as String?,
      source: json['source'] as String? ?? 'itunes',
    );
  }
}

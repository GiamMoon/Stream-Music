class Track {
  final String id;
  final String title;
  final String artistId;
  final String artistName;
  final String albumId;
  final int durationMs;
  final String streamUrl;
  final String? canvasUrl;
  final String? coverUrl; // NUEVO: URL de la carátula específica
  final bool hasLyrics;
  final bool isExplicit;
  
  // Créditos
  final List<String> producers;
  final List<String> writers;
  final String label;

  Track({
    required this.id,
    required this.title,
    required this.artistId,
    this.artistName = "Artista Desconocido",
    required this.albumId,
    required this.durationMs,
    required this.streamUrl,
    this.canvasUrl,
    this.coverUrl,
    required this.hasLyrics,
    required this.isExplicit,
    this.producers = const [],
    this.writers = const [],
    this.label = "Sello Independiente",
  });

  // Constructor para tu Backend Go (Mantenemos compatibilidad)
  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sin título',
      artistId: json['artist_id'] ?? '',
      artistName: json['artist_name'] ?? 'Artista',
      albumId: json['album_id'] ?? '',
      durationMs: json['duration_ms'] ?? 0,
      streamUrl: json['stream_url'] ?? '',
      canvasUrl: json['canvas_url'],
      hasLyrics: json['has_lyrics'] ?? false,
      isExplicit: json['is_explicit'] ?? false,
      producers: (json['producers'] as List?)?.map((e) => e.toString()).toList() ?? [],
      writers: (json['writers'] as List?)?.map((e) => e.toString()).toList() ?? [],
      label: json['label'] ?? "Music Label",
    );
  }

  // NUEVO: Constructor para API de Deezer
  factory Track.fromDeezer(Map<String, dynamic> json) {
    return Track(
      id: json['id'].toString(),
      title: json['title'] ?? 'Desconocido',
      artistId: json['artist']['id'].toString(),
      artistName: json['artist']['name'] ?? 'Artista',
      albumId: json['album']['id'].toString(),
      durationMs: (json['duration'] ?? 0) * 1000, // Deezer da segundos
      streamUrl: json['preview'] ?? '', // Preview de 30s
      coverUrl: json['album']['cover_xl'] ?? json['album']['cover_medium'],
      canvasUrl: null, // Deezer no da video
      hasLyrics: true, // Asumimos true para buscar en LRCLIB
      isExplicit: json['explicit_lyrics'] ?? false,
      label: "Deezer Content",
    );
  }
}

// --- CLASE PLAYLIST ---
class Playlist {
  final String id;
  final String name;
  final String description;
  final List<Track> tracks;

  Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.tracks,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    var list = json['tracks'] as List? ?? [];
    List<Track> tracksList = list.map((i) => Track.fromJson(i)).toList();

    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      tracks: tracksList,
    );
  }
}
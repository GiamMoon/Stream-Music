class Track {
  final String id;
  final String title;
  final String artistId;
  final String artistName;
  final String albumId;
  final int durationMs;
  final String streamUrl;
  final String? canvasUrl;
  final String? coverUrl;
  final bool hasLyrics;
  final bool isExplicit;
  
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

  factory Track.fromDeezer(Map<String, dynamic> json) {
    return Track(
      id: json['id'].toString(),
      title: json['title'] ?? 'Desconocido',
      
      // SOLUCIÓN DEL ERROR: Verificamos si 'artist' existe antes de leer
      artistId: json['artist'] != null ? json['artist']['id'].toString() : '0',
      artistName: json['artist'] != null ? json['artist']['name'] : 'Artista',
      
      // SOLUCIÓN DEL ERROR: Verificamos si 'album' existe antes de leer
      // En la lista de canciones de un álbum, esto suele venir nulo.
      albumId: json['album'] != null ? json['album']['id'].toString() : '0',
      
      durationMs: (json['duration'] ?? 0) * 1000,
      streamUrl: json['preview'] ?? '',
      
      // Verificamos si hay carátula
      coverUrl: json['album'] != null 
          ? (json['album']['cover_xl'] ?? json['album']['cover_medium']) 
          : null,
          
      canvasUrl: null,
      hasLyrics: true,
      isExplicit: json['explicit_lyrics'] ?? false,
      label: "Deezer Content",
    );
  }

  // Helper para asignarle la foto del álbum manualmente
  // (Porque la API no la manda en la lista de canciones del álbum)
  Track copyWithCover(String newCoverUrl) {
    return Track(
      id: id,
      title: title,
      artistId: artistId,
      artistName: artistName,
      albumId: albumId,
      durationMs: durationMs,
      streamUrl: streamUrl,
      canvasUrl: canvasUrl,
      coverUrl: newCoverUrl, // <--- Aquí cambiamos la foto
      hasLyrics: hasLyrics,
      isExplicit: isExplicit,
      producers: producers,
      writers: writers,
      label: label,
    );
  }
}

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
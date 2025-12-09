class Album {
  final String id;
  final String title;
  final String coverUrl;
  final String artistName;

  Album({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.artistName,
  });

  // Esta función convierte los datos "feos" que vienen de internet (JSON)
  // en un objeto Álbum ordenado que podemos usar en la app.
  factory Album.fromDeezer(Map<String, dynamic> json) {
    return Album(
      id: json['id'].toString(),
      title: json['title'] ?? 'Sin título',
      // Deezer a veces manda la imagen como 'cover_xl' y a veces como 'cover_medium'.
      // Aquí intentamos leer la grande, y si no existe, usamos la mediana.
      coverUrl: json['cover_xl'] ?? json['cover_medium'] ?? '',
      
      // A veces el nombre del artista viene dentro de una cajita llamada 'artist',
      // y a veces no viene. Aquí nos aseguramos de no romper la app si falta.
      artistName: json['artist'] != null ? json['artist']['name'] : 'Artista', 
    );
  }
}
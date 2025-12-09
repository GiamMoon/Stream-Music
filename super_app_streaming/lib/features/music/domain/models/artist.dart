class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final int popularity;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.popularity,
  });

  // Factory para tu Backend Go
  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Desconocido',
      imageUrl: json['image_url'] ?? '',
      popularity: json['popularity'] ?? 0,
    );
  }

  // NUEVO: Factory para Deezer
  factory Artist.fromDeezer(Map<String, dynamic> json) {
    return Artist(
      id: json['id'].toString(),
      name: json['name'] ?? 'Desconocido',
      imageUrl: json['picture_xl'] ?? json['picture_medium'] ?? '',
      popularity: 100, // Deezer ya los ordena por popularidad
    );
  }
}
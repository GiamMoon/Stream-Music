import 'package:dio/dio.dart';
import 'package:super_app_streaming/core/config/api_config.dart';
import 'package:super_app_streaming/core/network/dio_client.dart';
import 'package:super_app_streaming/features/music/domain/models/artist.dart';
import 'package:super_app_streaming/features/music/domain/models/track.dart'; // Import nuevo
import 'package:super_app_streaming/features/music/domain/models/lyric.dart'; // Import nuevo

class MusicRepositoryImpl {
  final Dio _dio = DioClient().dio;

  // 1. Obtener artistas para las burbujas
  Future<List<Artist>> getTrendingArtists() async {
    try {
      final response = await _dio.get(ApiConfig.trendingArtists);
      
      // Convertimos la lista de JSONs a lista de objetos Artist
      final List<dynamic> data = response.data;
      return data.map((json) => Artist.fromJson(json)).toList();
      
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Error cargando artistas');
    }
  }

Future<Playlist> getWelcomeMix() async {
    try {
      final response = await _dio.get(ApiConfig.welcomeMix);
      
      // Convertimos el JSON completo a un objeto Playlist
      return Playlist.fromJson(response.data);
      
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Error generando mix');
    }
  }

  Future<List<Lyric>> getTrackLyrics(String trackId) async {
    try {
      // Endpoint: /music/tracks/:id/lyrics
      final response = await _dio.get('/music/tracks/$trackId/lyrics');
      
      final List<dynamic> data = response.data;
      return data.map((json) => Lyric.fromJson(json)).toList();
    } on DioException catch (e) {
      // Si falla (ej. 404 no tiene letras), devolvemos lista vacía para no romper la UI
      print("Error obteniendo letras: ${e.message}");
      return []; 
    }
  }
}
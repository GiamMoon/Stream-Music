import 'package:dio/dio.dart';
import 'package:super_app_streaming/core/config/api_config.dart';
import 'package:super_app_streaming/core/utils/logger_service.dart';
import 'package:super_app_streaming/features/music/domain/models/artist.dart';
import 'package:super_app_streaming/features/music/domain/models/lyric.dart';
import 'package:super_app_streaming/features/music/domain/models/track.dart';
import 'package:super_app_streaming/features/music/domain/models/album.dart'; // <--- IMPORTANTE: Importamos el modelo que creaste en el Paso 1

class ExternalMusicRepository {
  final Dio _dio = Dio();
  final Dio _backendDio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  // --- MÉTODOS EXISTENTES (Los mantenemos) ---

  // 1. Obtener Top Artistas
  Future<List<Artist>> getTrendingArtists({int offset = 0, int limit = 30}) async {
    try {
      final response = await _dio.get(
        'https://api.deezer.com/chart/0/artists',
        queryParameters: {'index': offset, 'limit': limit},
      );
      final List data = response.data['data'];
      return data.map((json) => Artist.fromDeezer(json)).toList();
    } catch (e) {
      logger.e("Error fetching trending artists: $e");
      return [];
    }
  }

  // 1.1 Buscar Artistas
  Future<List<Artist>> searchArtists(String query) async {
    if (query.isEmpty) return getTrendingArtists(limit: 30);
    try {
      final response = await _dio.get(
        'https://api.deezer.com/search/artist',
        queryParameters: {'q': query, 'limit': 30},
      );
      final List data = response.data['data'];
      return data.map((json) => Artist.fromDeezer(json)).toList();
    } catch (e) {
      logger.e("Error searching artists: $e");
      return [];
    }
  }

  // 2. Generar Mix (Dejamos una versión simple si no usas la compleja)
  Future<Playlist> getPersonalizedMix(List<String> artistIds) async {
    // Si tienes tu lógica anterior aquí, mantenla. Esta es una versión segura:
    return Playlist(id: 'mix_custom', name: 'Tu Mix', description: 'Personalizado', tracks: []);
  }

  // 3. Obtener Letras
  Future<List<Lyric>> getTrackLyrics(String trackId, String artistName, String trackName, double durationSec) async {
    try {
      final response = await _dio.get(
        'https://lrclib.net/api/get',
        queryParameters: {
          'artist_name': artistName,
          'track_name': trackName,
          'duration': durationSec,
        },
      );

      if (response.data['syncedLyrics'] != null) {
        return _parseLrc(response.data['syncedLyrics']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 4. Sincronizar con Backend
  Future<void> syncTrackToBackend(Track track, String finalStreamUrl) async {
    try {
      final payload = {
        "deezer_id": track.id,
        "title": track.title,
        "duration": track.durationMs,
        "stream_url": finalStreamUrl,
        "cover": track.coverUrl ?? "",
        "artist_name": track.artistName,
        "artist_image": track.coverUrl ?? "",
        "album_title": "Single/Album"
      };
      await _backendDio.post(ApiConfig.syncTrack, data: payload);
    } catch (e) {
      // Ignoramos errores de sync silenciosamente
    }
  }

  // --- NUEVOS MÉTODOS PARA EL HOME DINÁMICO ---

  // A. Obtener Álbumes de un Artista
  Future<List<Album>> getArtistAlbums(String artistId) async {
    try {
      final response = await _dio.get('https://api.deezer.com/artist/$artistId/albums');
      final List data = response.data['data'];
      return data.map((json) => Album.fromDeezer(json)).toList();
    } catch (e) {
      logger.e("Error fetching albums: $e");
      return [];
    }
  }

  // B. Obtener Top Canciones de un Artista
  Future<List<Track>> getArtistTopTracks(String artistId) async {
    try {
      final response = await _dio.get('https://api.deezer.com/artist/$artistId/top?limit=10');
      final List data = response.data['data'];
      return data.map((json) => Track.fromDeezer(json)).toList();
    } catch (e) {
      logger.e("Error fetching top tracks: $e");
      return [];
    }
  }

  // C. Obtener Artistas Relacionados
  Future<List<Artist>> getRelatedArtists(String artistId) async {
    try {
      final response = await _dio.get('https://api.deezer.com/artist/$artistId/related');
      final List data = response.data['data'];
      return data.map((json) => Artist.fromDeezer(json)).toList();
    } catch (e) {
      logger.e("Error fetching related artists: $e");
      return [];
    }
  }

  // D. Obtener Canciones de un Álbum (Para la pantalla de Detalle)
  Future<List<Track>> getAlbumTracks(String albumId) async {
    try {
      final response = await _dio.get('https://api.deezer.com/album/$albumId/tracks');
      final List data = response.data['data'];
      return data.map((json) => Track.fromDeezer(json)).toList();
    } catch (e) {
      logger.e("Error fetching album tracks: $e");
      return [];
    }
  }

  // Helper privado para LRC
  List<Lyric> _parseLrc(String lrcContent) {
    final List<Lyric> lyrics = [];
    final lines = lrcContent.split('\n');
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\](.*)');

    for (var line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          lyrics.add(Lyric(
            time: Duration(minutes: minutes, seconds: seconds, milliseconds: milliseconds * 10),
            text: text,
          ));
        }
      }
    }
    return lyrics;
  }
}
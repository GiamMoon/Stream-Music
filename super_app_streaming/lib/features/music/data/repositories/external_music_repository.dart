import 'package:dio/dio.dart';
import 'package:super_app_streaming/core/config/api_config.dart';
import 'package:super_app_streaming/core/utils/logger_service.dart';
import 'package:super_app_streaming/features/music/domain/models/artist.dart';
import 'package:super_app_streaming/features/music/domain/models/lyric.dart';
import 'package:super_app_streaming/features/music/domain/models/track.dart';

class ExternalMusicRepository {
  final Dio _dio = Dio();
  final Dio _backendDio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  // 1. Obtener Top Artistas (CON PAGINACIÓN)
  // offset: cuántos nos saltamos (0, 30, 60...)
  // limit: cuántos traemos (30)
  Future<List<Artist>> getTrendingArtists({int offset = 0, int limit = 30}) async {
    try {
      final response = await _dio.get(
        'https://api.deezer.com/chart/0/artists',
        queryParameters: {
          'index': offset,
          'limit': limit,
        },
      );
      final List data = response.data['data'];
      return data.map((json) => Artist.fromDeezer(json)).toList();
    } catch (e) {
      logger.e("Error Deezer Artists: $e");
      return [];
    }
  }

  // 1.1 Buscar Artistas (Search Bar)
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
      logger.e("Error buscando artistas: $e");
      return [];
    }
  }

  // 2. Generar Mix Personalizado
  Future<Playlist> getPersonalizedMix(List<String> artistIds) async {
    try {
      List<Track> mixedTracks = [];

      if (artistIds.isEmpty) {
        final response = await _dio.get('https://api.deezer.com/chart/0/tracks?limit=50');
        final List data = response.data['data'];
        mixedTracks = data.map((json) => Track.fromDeezer(json)).toList();
      } else {
        // Traemos más canciones por artista para llenar el mix
        for (String artistId in artistIds) {
          try {
            final response = await _dio.get('https://api.deezer.com/artist/$artistId/top?limit=10');
            final List data = response.data['data'];
            final artistTracks = data.map((json) => Track.fromDeezer(json)).toList();
            mixedTracks.addAll(artistTracks);
          } catch (e) {
            logger.w("No se pudieron cargar tracks del artista $artistId");
          }
        }
        mixedTracks.shuffle();
      }

      return Playlist(
        id: 'mix_custom_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Tu Mix Personalizado',
        description: 'Basado en tus artistas favoritos',
        tracks: mixedTracks,
      );
    } catch (e) {
      throw Exception("Error generando mix personalizado: $e");
    }
  }

  // 3. Obtener Letras (LRCLIB)
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

  // 4. Sincronizar con Backend Go
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
      logger.t("💾 Sync OK: ${track.title}");
    } catch (e) {
      // Fail silently
    }
  }

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
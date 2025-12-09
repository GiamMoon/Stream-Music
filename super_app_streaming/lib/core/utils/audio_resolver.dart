import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:super_app_streaming/core/utils/logger_service.dart';

class AudioResolver {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Obtiene el link de audio real en milisegundos
  Future<String> getFullAudioUrl(String artist, String title) async {
    try {
      final query = "$artist - $title audio";
      
      // 1. Buscar video (Esto suele tardar 1-2 segs máximo)
      final searchResult = await _yt.search.search(query);
      if (searchResult.isEmpty) return "";

      final videoId = searchResult.first.id.value;

      // 2. Obtener el manifiesto de streams
      // TRUCO DE VELOCIDAD: Usamos 'androidVr' y 'ios' como indica tu documentación.
      // Esto evita el throttling y hace que cargue mucho más rápido.
      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [
          YoutubeApiClient.androidVr,
          YoutubeApiClient.ios,
        ],
      );
      
      // 3. Obtener solo audio de la mejor calidad posible
      // .audioOnly filtra los videos, .withHighestBitrate() asegura la mejor calidad de sonido
      final audioStream = manifest.audioOnly.withHighestBitrate();
      
      // 4. Retornar URL directa
      // Esta URL es la que el AudioPlayer puede reproducir directamente sin descargar el archivo
      return audioStream.url.toString();

    } catch (e) {
      logger.e("Error resolviendo audio con YoutubeExplode: $e");
      return "";
    }
  }

  void dispose() {
    _yt.close();
  }
}
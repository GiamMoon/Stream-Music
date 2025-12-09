import 'package:dio/dio.dart';

class HlsParser {
  final Dio _dio = Dio();

  // Recibe la URL Maestra y la preferencia de calidad ('low', 'mid', 'high')
  Future<String> getStreamUrlByQuality(String masterUrl, String qualityPreference) async {
    // 1. Si no es un m3u8 (es mp3 directo), devolvemos la URL tal cual
    if (!masterUrl.contains('.m3u8')) return masterUrl;

    try {
      // 2. Descargamos el contenido del archivo de texto .m3u8
      final response = await _dio.get(masterUrl);
      final content = response.data.toString();

      // 3. Parseamos las líneas para encontrar los variantes y sus bitrates
      // Formato típico:
      // #EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
      // 800k/prog_index.m3u8
      
      final lines = content.split('\n');
      String? selectedUrl;
      int closestBandwidthDiff = 999999999;
      int targetBandwidth;

      // Definimos el ancho de banda objetivo según la preferencia
      switch (qualityPreference) {
        case 'Data Saver':
          targetBandwidth = 64000; // 64kbps
          break;
        case 'High':
          targetBandwidth = 320000; // 320kbps
          break;
        case 'HiFi / Master':
          targetBandwidth = 10000000; // Lo más alto posible
          break;
        case 'Normal':
        default:
          targetBandwidth = 160000; // 160kbps
      }

      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('#EXT-X-STREAM-INF')) {
          // Extraer BANDWIDTH
          final bandwidthMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(lines[i]);
          if (bandwidthMatch != null) {
            final bandwidth = int.parse(bandwidthMatch.group(1)!);
            final diff = (bandwidth - targetBandwidth).abs();

            // Buscamos el que esté más cerca de nuestro objetivo
            if (diff < closestBandwidthDiff) {
              closestBandwidthDiff = diff;
              // La URL está en la siguiente línea
              if (i + 1 < lines.length) {
                 selectedUrl = lines[i + 1].trim();
              }
            }
          }
        }
      }

      // 4. Reconstruir la URL completa
      if (selectedUrl != null && selectedUrl.isNotEmpty) {
        // Si la URL es relativa, le pegamos la base de la URL maestra
        if (!selectedUrl.startsWith('http')) {
           final baseUrl = masterUrl.substring(0, masterUrl.lastIndexOf('/') + 1);
           return baseUrl + selectedUrl;
        }
        return selectedUrl;
      }

      return masterUrl; // Fallback: URL original
    } catch (e) {
      print("Error parseando HLS: $e");
      return masterUrl; // Fallback ante error
    }
  }
}
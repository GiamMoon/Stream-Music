import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    const myPcIp = '192.168.18.17'; // <--- ¡PON TU IP AQUÍ! (Ej: 192.168.1.35)
if (Platform.isAndroid) {
      return 'http://$myPcIp:8080'; 
    } else {
      return 'http://localhost:8080';
    }
  }

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String trendingArtists = '/music/artists/trending';
  static const String welcomeMix = '/music/recommendations/mix';
  static const String syncTrack = '/music/sync/track'; // <--- NUEVO
}
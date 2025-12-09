import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart'; // <--- IMPORTANTE
import 'package:super_app_streaming/core/app_theme.dart';
import 'package:super_app_streaming/core/router/app_router.dart';
import 'package:super_app_streaming/features/player/logic/audio_player_handler.dart';

// Variables globales
late AudioHandler audioHandler;
final MiniplayerController miniplayerController = MiniplayerController(); // <--- NUEVA VARIABLE GLOBAL

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INICIALIZACIÓN DEL SERVICIO DE AUDIO
  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.tuapp.streaming.channel.audio',
      androidNotificationChannelName: 'Reproducción de Música',
      androidNotificationOngoing: true,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Super App Streaming',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
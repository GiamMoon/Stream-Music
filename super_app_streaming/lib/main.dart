import 'package:audio_service/audio_service.dart'; // Importar
import 'package:flutter/material.dart';
import 'package:super_app_streaming/core/app_theme.dart';
import 'package:super_app_streaming/core/router/app_router.dart';
import 'package:super_app_streaming/features/player/logic/audio_player_handler.dart'; // Importar tu handler

// Variable global para acceder al reproductor desde cualquier lado
late AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Necesario para inicializar servicios antes de UI

  // INICIALIZACIÓN DEL SERVICIO DE AUDIO (BACKGROUND)
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
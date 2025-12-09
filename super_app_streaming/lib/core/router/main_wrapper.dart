import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:super_app_streaming/features/player/presentation/screens/player_screen.dart';
import 'package:super_app_streaming/features/player/presentation/widgets/mini_player.dart';
import 'package:super_app_streaming/main.dart'; // Importante para acceder a miniplayerController

class MainWrapper extends StatefulWidget {
  final Widget child;

  const MainWrapper({super.key, required this.child});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  // YA NO creamos el controlador aquí, usamos el global importado de main.dart

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo (Home, Perfil, etc)
          widget.child,

          // Reproductor Persistente
          StreamBuilder<MediaItem?>(
            stream: audioHandler.mediaItem,
            builder: (context, snapshot) {
              if (snapshot.data == null) return const SizedBox.shrink();

              return Miniplayer(
                controller: miniplayerController, // <--- USAMOS LA GLOBAL
                minHeight: 70,
                maxHeight: MediaQuery.of(context).size.height,
                builder: (height, percentage) {
                  if (percentage > 0.2) {
                    return PlayerScreen(
                      isEmbedded: true, 
                      controller: miniplayerController, // <--- SE LA PASAMOS AL PLAYER
                    );
                  } else {
                    return const MiniPlayerWidget();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
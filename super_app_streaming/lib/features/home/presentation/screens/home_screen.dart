import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:super_app_streaming/features/music/domain/models/track.dart';
import 'package:super_app_streaming/main.dart'; // Para audioHandler y miniplayerController
import 'package:super_app_streaming/features/player/logic/audio_player_handler.dart';

class HomeScreen extends StatelessWidget {
  final Playlist? initialPlaylist;

  const HomeScreen({super.key, this.initialPlaylist});

  @override
  Widget build(BuildContext context) {
    final firstTrack = initialPlaylist?.tracks.firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () {
              context.push('/profile');
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (firstTrack != null) ...[
              // Carátula
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                  image: firstTrack.coverUrl != null 
                    ? DecorationImage(
                        image: NetworkImage(firstTrack.coverUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: firstTrack.coverUrl == null 
                  ? const Icon(Icons.music_note, size: 80, color: Colors.white) 
                  : null,
              ),
              
              const SizedBox(height: 20),
              
              Text(
                "Reproduciendo Ahora:",
                style: TextStyle(color: Colors.green.shade400, letterSpacing: 1.2),
              ),
              
              const SizedBox(height: 10),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  firstTrack.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              
              Text(
                firstTrack.artistName,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              
              const SizedBox(height: 30),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_fill),
                label: const Text("REPRODUCIR"),
                onPressed: () {
                  if (initialPlaylist != null && initialPlaylist!.tracks.isNotEmpty) {
                    
                    final handler = audioHandler as AudioPlayerHandler;
                    
                    // 1. Iniciar reproducción
                    handler.playFromPlaylist(initialPlaylist!.tracks, 0);
                    
                    // 2. Expandir el Miniplayer automáticamente
                    // SOLUCIÓN: Usamos el controlador global directamente
                    miniplayerController.animateToHeight(state: PanelState.MAX);
                  }
                },
              )
            ] else
              const Text("No hay música seleccionada. Ve a Onboarding."),
          ],
        ),
      ),
    );
  }
}
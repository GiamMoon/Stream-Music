import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:super_app_streaming/main.dart'; // Para audioHandler

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        if (mediaItem == null) return const SizedBox.shrink();

        return Container(
          color: const Color(0xFF282828), 
          height: 70, 
          child: Column(
            children: [
              // Barra de progreso superior
              StreamBuilder<Duration>(
                stream: AudioService.position,
                builder: (context, posSnap) {
                   final pos = posSnap.data ?? Duration.zero;
                   final total = mediaItem.duration ?? Duration.zero;
                   
                   double progress = 0.0;
                   if (total.inMilliseconds > 0) {
                     progress = pos.inMilliseconds / total.inMilliseconds;
                   }
                   if(progress > 1) progress = 1;
                   if(progress < 0) progress = 0;
                   
                   return LinearProgressIndicator(
                     value: progress, 
                     minHeight: 2, 
                     backgroundColor: Colors.transparent,
                     valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
                   );
                }
              ),

              // Contenido Principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      // Carátula pequeña
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: mediaItem.artUri?.toString() ?? '',
                          width: 48, 
                          height: 48, 
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(color: Colors.grey.shade800, child: const Icon(Icons.music_note, color: Colors.white)),
                          placeholder: (_, __) => Container(color: Colors.grey.shade800),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Título y Artista
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mediaItem.title, 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mediaItem.artist ?? 'Desconocido', 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      // Botón Play/Pause con Spinner
                      StreamBuilder<PlaybackState>(
                        stream: audioHandler.playbackState,
                        builder: (context, stateSnap) {
                          final playing = stateSnap.data?.playing ?? false;
                          final processingState = stateSnap.data?.processingState;
                          final isLoading = processingState == AudioProcessingState.loading || 
                                            processingState == AudioProcessingState.buffering;

                          if (isLoading) {
                            return const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            );
                          }

                          return IconButton(
                            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                            color: Colors.white,
                            onPressed: playing ? audioHandler.pause : audioHandler.play,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
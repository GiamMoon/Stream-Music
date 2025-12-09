import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:super_app_streaming/core/utils/logger_service.dart';
import 'package:super_app_streaming/features/music/data/repositories/external_music_repository.dart';
import 'package:super_app_streaming/main.dart'; 

class PlayerScreen extends StatefulWidget {
  final bool isEmbedded;
  final MiniplayerController? controller;

  const PlayerScreen({
    super.key,
    this.isEmbedded = false,
    this.controller,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _musicRepo = ExternalMusicRepository();

  void _openLyrics() async {
    final item = audioHandler.mediaItem.value;
    if (item == null) return;

    final trackId = item.extras?['original_id'] ?? "";
    final artist = item.artist ?? "";
    final title = item.title;
    final duration = (item.duration?.inMilliseconds ?? 0) / 1000.0;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Buscando letras..."), duration: Duration(milliseconds: 800),
    ));

    try {
      final lyrics = await _musicRepo.getTrackLyrics(trackId.toString(), artist, title, duration);
      
      if (mounted) {
        context.push('/lyrics', extra: {
          'artworkUrl': item.artUri?.toString() ?? "",
          'lyrics': lyrics
        });
      }
    } catch (e) {
      logger.e("Error lyrics: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) return const Scaffold(backgroundColor: Colors.black);
        
        final artworkUrl = mediaItem.artUri?.toString() ?? "";

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.white),
              onPressed: () {
                if (widget.isEmbedded && widget.controller != null) {
                  widget.controller!.animateToHeight(state: PanelState.MIN);
                } else {
                  context.pop();
                }
              },
            ),
            title: Text(
              mediaItem.title.toUpperCase(),
              style: TextStyle(fontSize: 12, letterSpacing: 1, color: Colors.white.withOpacity(0.7)),
            ),
            centerTitle: true,
            actions: [
              IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
            ],
          ),
          body: Stack(
            children: [
              // 1. FONDO
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: artworkUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(color: Colors.black),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),

              // 2. CONTENIDO (ADAPTABLE E INTELIGENTE)
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        // Esto fuerza a que el contenido tenga AL MENOS la altura de la pantalla
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: IntrinsicHeight(
                            child: Column(
                              children: [
                                // Espacio flexible arriba (se encoge si falta espacio)
                                const Spacer(), 
                                
                                // 3. CARÁTULA
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 30, offset: const Offset(0, 20))],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: artworkUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 40),
                                
                                // Textos
                                Text(mediaItem.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1),
                                const SizedBox(height: 6),
                                Text(mediaItem.artist ?? '', style: const TextStyle(color: Colors.white70, fontSize: 16), maxLines: 1),
                                
                                const SizedBox(height: 24),

                                // 4. BARRA DE PROGRESO
                                StreamBuilder<PlaybackState>(
                                  stream: audioHandler.playbackState,
                                  builder: (context, stateSnap) {
                                    final processingState = stateSnap.data?.processingState;
                                    final isBuffering = processingState == AudioProcessingState.buffering ||
                                                        processingState == AudioProcessingState.loading;

                                    return StreamBuilder<Duration>(
                                      stream: AudioService.position,
                                      builder: (context, posSnap) {
                                        final position = isBuffering ? Duration.zero : (posSnap.data ?? Duration.zero);
                                        final total = isBuffering ? Duration.zero : (mediaItem.duration ?? Duration.zero);

                                        return ProgressBar(
                                          progress: position,
                                          total: total,
                                          onSeek: audioHandler.seek,
                                          baseBarColor: Colors.white24,
                                          progressBarColor: Colors.white,
                                          thumbColor: Colors.white,
                                          timeLabelLocation: TimeLabelLocation.sides,
                                          timeLabelTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                        );
                                      },
                                    );
                                  },
                                ),

                                const SizedBox(height: 20),

                                // 5. CONTROLES
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.skip_previous, color: Colors.white, size: 42), 
                                      onPressed: audioHandler.skipToPrevious
                                    ),
                                    
                                    StreamBuilder<PlaybackState>(
                                      stream: audioHandler.playbackState,
                                      builder: (context, snapshot) {
                                        final playing = snapshot.data?.playing ?? false;
                                        final processingState = snapshot.data?.processingState;
                                        final isLoading = processingState == AudioProcessingState.loading || 
                                                          processingState == AudioProcessingState.buffering;

                                        return Container(
                                          width: 72, height: 72,
                                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                          child: isLoading 
                                            ? const Padding(
                                                padding: EdgeInsets.all(20.0),
                                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                                              )
                                            : IconButton(
                                                icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 38),
                                                onPressed: playing ? audioHandler.pause : audioHandler.play,
                                              ),
                                        );
                                      },
                                    ),
                                    
                                    IconButton(
                                      icon: const Icon(Icons.skip_next, color: Colors.white, size: 42), 
                                      onPressed: audioHandler.skipToNext
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Botones inferiores
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(icon: const Icon(Icons.lyrics_outlined, color: Colors.white), onPressed: _openLyrics),
                                    IconButton(icon: const Icon(Icons.list, color: Colors.white), onPressed: () {}),
                                  ],
                                ),
                                
                                // Espacio flexible abajo (se encoge si falta espacio)
                                const Spacer(),
                                const SizedBox(height: 20), // Un margen mínimo de seguridad
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
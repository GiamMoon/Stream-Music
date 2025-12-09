import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:super_app_streaming/core/utils/audio_resolver.dart';
import 'package:super_app_streaming/core/utils/logger_service.dart';
import 'package:super_app_streaming/features/music/data/repositories/external_music_repository.dart'; 
import 'package:super_app_streaming/features/music/domain/models/track.dart';
import 'package:super_app_streaming/features/player/logic/audio_player_handler.dart';
import 'package:super_app_streaming/main.dart';

class PlayerScreen extends StatefulWidget {
  final List<Track> playlist;
  final int initialIndex;

  const PlayerScreen({
    super.key, 
    required this.playlist, 
    required this.initialIndex
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _musicRepo = ExternalMusicRepository();
  final _audioResolver = AudioResolver();
  
  bool _isLoadingAudio = true;
  bool _hasError = false;
  // Estado local para saber si estamos buscando el link (Spinner central)
  bool _isResolving = false;
  String? _lastResolvedId; 

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      final initialTrack = widget.playlist[widget.initialIndex];
      
      // 1. Resolver Primera Canción
      final streamUrl = await _audioResolver.getFullAudioUrl(
        initialTrack.artistName, 
        initialTrack.title
      );

      if (streamUrl.isEmpty) throw Exception("No audio found");

      List<MediaItem> mediaItems = widget.playlist.asMap().entries.map((entry) {
        final track = entry.value;
        final index = entry.key;
        final isCurrent = index == widget.initialIndex;
        
        return MediaItem(
          id: isCurrent ? streamUrl : "", 
          album: "Mix Personalizado",
          title: track.title,
          artist: track.artistName,
          artUri: track.coverUrl != null ? Uri.parse(track.coverUrl!) : null,
          duration: Duration(milliseconds: track.durationMs),
          extras: {
            'original_id': track.id, 
            'artist_name': track.artistName,
            'track_title': track.title,
          },
        );
      }).toList();

      if (audioHandler is AudioPlayerHandler) {
        await (audioHandler as AudioPlayerHandler).loadPlaylist(mediaItems, widget.initialIndex);
      }
      
      _setupSmartResolution();

      if (mounted) setState(() => _isLoadingAudio = false);
      _musicRepo.syncTrackToBackend(initialTrack, streamUrl);

    } catch (e) {
      if (mounted) setState(() { _isLoadingAudio = false; _hasError = true; });
    }
  }

  void _setupSmartResolution() {
    audioHandler.mediaItem.listen((mediaItem) async {
      if (mediaItem == null) return;
      
      // Si la canción no tiene URL (id vacío) y es diferente a la última resuelta
      if (mediaItem.id.isEmpty && mediaItem.extras?['original_id'] != _lastResolvedId) {
        _lastResolvedId = mediaItem.extras?['original_id'];
        
        // ACTIVAR SPINNER
        if (mounted) setState(() => _isResolving = true);
        
        logger.i("⚡ Resolviendo rápido: ${mediaItem.title}...");

        final url = await _audioResolver.getFullAudioUrl(
          mediaItem.artist ?? "", 
          mediaItem.title
        );

        if (url.isNotEmpty && audioHandler is AudioPlayerHandler) {
          (audioHandler as AudioPlayerHandler).playResolvedUrl(url);
          // DESACTIVAR SPINNER
          if (mounted) setState(() => _isResolving = false);
        } else {
           if (mounted) setState(() => _isResolving = false);
        }
      } else {
        // Si ya tiene URL o es la misma, asegurarnos de quitar el spinner
        if (_isResolving && mounted) setState(() => _isResolving = false);
      }
    });
  }

  void _openLyrics() async {
     final item = audioHandler.mediaItem.value;
     if (item == null) return;

     final trackId = item.extras?['original_id'] ?? "";
     final artist = item.artist ?? "";
     final title = item.title;
     final duration = (item.duration?.inMilliseconds ?? 0) / 1000.0;
     
     final lyrics = await _musicRepo.getTrackLyrics(trackId.toString(), artist, title, duration);
     
     if (mounted) {
       context.push('/lyrics', extra: {
         'artworkUrl': item.artUri?.toString() ?? "",
         'lyrics': lyrics
       });
     }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAudio) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (_hasError) {
       return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, leading: BackButton(color: Colors.white, onPressed: () => context.pop())),
        body: const Center(child: Text("Error de carga", style: TextStyle(color: Colors.white))),
      );
    }

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) return const SizedBox();
        final artworkUrl = mediaItem.artUri?.toString() ?? "";

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: Text(
              _isResolving ? "CARGANDO..." : "REPRODUCIENDO",
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

              // 2. CONTENIDO
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(),

                      // 3. CARÁTULA CON INDICADOR DE CARGA CENTRAL
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 30, offset: const Offset(0, 20))],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: artworkUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              // SPINNER CENTRAL: Se muestra si estamos resolviendo URL O si el player está buffering
                              StreamBuilder<PlaybackState>(
                                stream: audioHandler.playbackState,
                                builder: (context, stateSnap) {
                                  final isBuffering = stateSnap.data?.processingState == AudioProcessingState.buffering;
                                  // Mostrar si resolving (app) OR buffering (audio player)
                                  if (_isResolving || isBuffering) {
                                    return Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(50)),
                                      child: const CircularProgressIndicator(color: Colors.white),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      Text(mediaItem.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1),
                      const SizedBox(height: 6),
                      Text(mediaItem.artist ?? '', style: const TextStyle(color: Colors.white70, fontSize: 16), maxLines: 1),
                      const SizedBox(height: 24),

                      // 4. BARRA DE PROGRESO
                      StreamBuilder<Duration>(
                        stream: AudioService.position,
                        builder: (context, snapshot) {
                          return ProgressBar(
                            progress: snapshot.data ?? Duration.zero,
                            total: mediaItem.duration ?? Duration.zero,
                            onSeek: audioHandler.seek,
                            baseBarColor: Colors.white24,
                            progressBarColor: Colors.white,
                            thumbColor: Colors.white,
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // 5. CONTROLES PLAY/PAUSE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 42), onPressed: audioHandler.skipToPrevious),
                          
                          StreamBuilder<PlaybackState>(
                            stream: audioHandler.playbackState,
                            builder: (context, snapshot) {
                              final playing = snapshot.data?.playing ?? false;
                              // El botón de Play SIEMPRE debe estar disponible, incluso cargando, para poder pausar si se desea
                              return Container(
                                width: 72, height: 72,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                child: IconButton(
                                  icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 38),
                                  onPressed: playing ? audioHandler.pause : audioHandler.play,
                                ),
                              );
                            },
                          ),
                          
                          IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 42), onPressed: audioHandler.skipToNext),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(icon: const Icon(Icons.lyrics_outlined, color: Colors.white), onPressed: _openLyrics),
                          IconButton(icon: const Icon(Icons.list, color: Colors.white), onPressed: () {}),
                        ],
                      ),
                      const SizedBox(height: 20),
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
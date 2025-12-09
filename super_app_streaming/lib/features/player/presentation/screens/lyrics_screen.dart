import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:super_app_streaming/features/music/domain/models/lyric.dart';
import 'package:super_app_streaming/features/player/presentation/widgets/lyrics_display.dart';

class LyricsScreen extends StatelessWidget {
  final String artworkUrl;
  final List<Lyric> lyrics;

  const LyricsScreen({
    super.key,
    required this.artworkUrl,
    required this.lyrics,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 36, color: Colors.white),
          onPressed: () => context.pop(), // Vuelve al reproductor
        ),
        title: const Text("LETRA", style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Fondo: Misma carátula
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: artworkUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(color: Colors.black),
            ),
          ),
          
          // 2. Efecto Blur Intenso
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                color: Colors.black.withOpacity(0.6), // Oscurecer un poco más para legibilidad
              ),
            ),
          ),

          // 3. Letras Sincronizadas
          SafeArea(
            child: StreamBuilder<Duration>(
              stream: AudioService.position,
              builder: (context, snapshot) {
                return LyricsDisplay(
                  lyrics: lyrics,
                  currentPosition: snapshot.data ?? Duration.zero,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
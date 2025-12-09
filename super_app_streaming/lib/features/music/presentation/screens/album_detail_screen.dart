import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:super_app_streaming/features/music/data/repositories/external_music_repository.dart';
import 'package:super_app_streaming/features/music/domain/models/album.dart';
import 'package:super_app_streaming/features/music/domain/models/track.dart';
import 'package:super_app_streaming/features/player/logic/audio_player_handler.dart';
import 'package:super_app_streaming/main.dart'; 

class AlbumDetailScreen extends StatefulWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final _musicRepo = ExternalMusicRepository();
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    // 1. Obtenemos las canciones (vienen sin foto de álbum en este endpoint)
    final fetchedTracks = await _musicRepo.getAlbumTracks(widget.album.id);
    
    // 2. Les inyectamos la foto del álbum que ya tenemos en 'widget.album'
    final tracksWithCover = fetchedTracks.map((track) {
      return track.copyWithCover(widget.album.coverUrl);
    }).toList();

    if (mounted) {
      setState(() {
        _tracks = tracksWithCover;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. App Bar
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.album.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.album.coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade900),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Lista
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = _tracks[index];
                      return ListTile(
                        leading: Text(
                          "${index + 1}",
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          track.artistName,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.play_circle_outline, color: Colors.grey),
                        onTap: () {
                          // Reproducimos la lista con las fotos ya corregidas
                          final handler = audioHandler as AudioPlayerHandler;
                          handler.playFromPlaylist(_tracks, index);
                          miniplayerController.animateToHeight(state: PanelState.MAX);
                        },
                      );
                    },
                    childCount: _tracks.length,
                  ),
                ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
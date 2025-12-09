import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:super_app_streaming/features/music/data/repositories/external_music_repository.dart';
import 'package:super_app_streaming/features/music/domain/models/album.dart';
import 'package:super_app_streaming/features/music/domain/models/artist.dart';
import 'package:super_app_streaming/features/music/domain/models/track.dart';
import 'package:super_app_streaming/features/player/logic/audio_player_handler.dart';
import 'package:super_app_streaming/main.dart'; // Para audioHandler y miniplayerController

class ArtistDetailScreen extends StatefulWidget {
  final Artist artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final _musicRepo = ExternalMusicRepository();
  
  // Datos que vamos a cargar
  List<Track> _topTracks = [];
  List<Album> _albums = [];
  List<Artist> _related = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistData();
  }

  Future<void> _loadArtistData() async {
    try {
      // Cargamos todo en paralelo para que sea rápido
      final results = await Future.wait([
        _musicRepo.getArtistTopTracks(widget.artist.id),
        _musicRepo.getArtistAlbums(widget.artist.id),
        _musicRepo.getRelatedArtists(widget.artist.id),
      ]);

      if (mounted) {
        setState(() {
          _topTracks = results[0] as List<Track>;
          _albums = results[1] as List<Album>;
          _related = results[2] as List<Artist>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Cabecera con Foto del Artista
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.artist.name),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.artist.imageUrl,
                    fit: BoxFit.cover,
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

          // 2. Contenido (Filas)
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverList(
              delegate: SliverChildListDelegate([
                
                // Botón Gigante de "Reproducir Hits"
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("REPRODUCIR HITS"),
                    onPressed: () {
                      if (_topTracks.isNotEmpty) {
                        final handler = audioHandler as AudioPlayerHandler;
                        handler.playFromPlaylist(_topTracks, 0);
                        miniplayerController.animateToHeight(state: PanelState.MAX);
                      }
                    },
                  ),
                ),

                // Sección: Top Canciones
                if (_topTracks.isNotEmpty) ...[
                  _buildSectionTitle("Canciones Populares"),
                  // Mostramos solo las primeras 5 para no hacer la lista eterna
                  ..._topTracks.take(5).map((track) => ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(imageUrl: track.coverUrl ?? "", width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    title: Text(track.title, style: const TextStyle(color: Colors.white), maxLines: 1),
                    subtitle: Text(track.artistName, style: const TextStyle(color: Colors.grey), maxLines: 1),
                    trailing: const Icon(Icons.play_circle_outline, color: Colors.grey),
                    onTap: () {
                      final handler = audioHandler as AudioPlayerHandler;
                      handler.playFromPlaylist([track], 0);
                      miniplayerController.animateToHeight(state: PanelState.MAX);
                    },
                  )),
                ],

                // Sección: Álbumes
                if (_albums.isNotEmpty) ...[
                  _buildSectionTitle("Álbumes"),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _albums.length,
                      separatorBuilder: (_,__) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final album = _albums[index];
                        return _buildAlbumCard(context, album);
                      },
                    ),
                  ),
                ],

                // Sección: Relacionados
                if (_related.isNotEmpty) ...[
                  _buildSectionTitle("Fans también escuchan"),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _related.length,
                      separatorBuilder: (_,__) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                         final artist = _related[index];
                         return _buildArtistCircle(context, artist);
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 120), // Espacio final
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAlbumCard(BuildContext context, Album album) {
    return GestureDetector(
      onTap: () => context.push('/album_detail', extra: album), // Reutilizamos tu pantalla de Álbum
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(imageUrl: album.coverUrl, height: 120, width: 120, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Text("Álbum", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistCircle(BuildContext context, Artist artist) {
    return GestureDetector(
      onTap: () => context.push('/artist_detail', extra: artist), // Navegación recursiva a otro artista
      child: Column(
        children: [
          Container(
            height: 100, width: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(image: CachedNetworkImageProvider(artist.imageUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 100,
            child: Text(artist.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
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

class HomeScreen extends StatefulWidget {
  final Playlist? initialPlaylist;
  final List<String> selectedArtistIds;

  const HomeScreen({
    super.key, 
    this.initialPlaylist, 
    this.selectedArtistIds = const []
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _musicRepo = ExternalMusicRepository();
  
  // Aquí guardaremos las filas de contenido
  List<HomeSection> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  // --- CEREBRO DEL HOME ---
  Future<void> _loadHomeData() async {
    // Si no hay artistas seleccionados, terminamos rápido
    if (widget.selectedArtistIds.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    List<HomeSection> tempSections = [];

    // Recorremos cada artista favorito
    for (String artistId in widget.selectedArtistIds) {
      try {
        // Pedimos Albums, Tracks y Relacionados en paralelo
        final results = await Future.wait([
          _musicRepo.getArtistAlbums(artistId),    // Index 0
          _musicRepo.getArtistTopTracks(artistId), // Index 1
          _musicRepo.getRelatedArtists(artistId),  // Index 2
        ]);

        final albums = results[0] as List<Album>;
        final tracks = results[1] as List<Track>;
        final related = results[2] as List<Artist>;

        // Sacamos el nombre del artista para el título de la sección
        String artistName = "Tu Artista";
        if (tracks.isNotEmpty) artistName = tracks.first.artistName;
        else if (albums.isNotEmpty) artistName = albums.first.artistName;

        // Fila 1: Álbumes
        if (albums.isNotEmpty) {
          tempSections.add(HomeSection(title: "Álbumes de $artistName", items: albums, type: SectionType.album));
        }
        // Fila 2: Canciones
        if (tracks.isNotEmpty) {
          tempSections.add(HomeSection(title: "Top Canciones de $artistName", items: tracks, type: SectionType.track));
        }
        // Fila 3: Relacionados
        if (related.isNotEmpty) {
          tempSections.add(HomeSection(title: "Similares a $artistName", items: related, type: SectionType.artist));
        }

      } catch (e) {
        // Si falla un artista, seguimos con el siguiente
        print("Error cargando artista $artistId: $e");
      }
    }

    if (mounted) {
      setState(() {
        _sections = tempSections;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 16),
        ],
        backgroundColor: Colors.black,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. BANNER DEL MIX
                if (widget.initialPlaylist != null)
                   _buildMixBanner(context),
                
                const SizedBox(height: 20),

                // 2. FILAS DINÁMICAS
                if (_sections.isEmpty)
                   const Padding(padding: EdgeInsets.all(20), child: Text("No hay contenido. Prueba seleccionando artistas en el Onboarding."))
                else
                   ..._sections.map((section) => _buildSectionRow(context, section)),
                   
                // Espacio extra al final para el miniplayer
                const SizedBox(height: 100), 
              ],
            ),
          ),
    );
  }

  // Banner Grande (Tu Mix)
  Widget _buildMixBanner(BuildContext context) {
    final track = widget.initialPlaylist!.tracks.firstOrNull;
    if (track == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade900, Colors.black]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: track.coverUrl ?? "",
              width: 100, height: 100, fit: BoxFit.cover,
              errorWidget: (_,__,___) => const Icon(Icons.music_note, color: Colors.white, size: 50),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tu Mix Personalizado", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Basado en tus gustos", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                  onPressed: () {
                    final handler = audioHandler as AudioPlayerHandler;
                    handler.playFromPlaylist(widget.initialPlaylist!.tracks, 0);
                    miniplayerController.animateToHeight(state: PanelState.MAX);
                  },
                  child: const Text("REPRODUCIR"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget para cada Fila (Título + Lista Horizontal)
  Widget _buildSectionRow(BuildContext context, HomeSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            section.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        SizedBox(
          // CORRECCIÓN AQUÍ: Aumentamos de 140 a 160 para evitar el overflow en artistas
          height: section.type == SectionType.artist ? 160 : 180, 
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: section.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = section.items[index];
              return _buildCard(context, item, section.type);
            },
          ),
        ),
      ],
    );
  }

  // Widget de la Tarjeta Individual
  Widget _buildCard(BuildContext context, dynamic item, SectionType type) {
    String imageUrl = "";
    String title = "";
    String subtitle = "";
    bool isCircle = type == SectionType.artist;

    if (item is Album) {
      imageUrl = item.coverUrl;
      title = item.title;
      subtitle = "Álbum";
    } else if (item is Track) {
      imageUrl = item.coverUrl ?? "";
      title = item.title;
      subtitle = item.artistName;
    } else if (item is Artist) {
      imageUrl = item.imageUrl;
      title = item.name;
      subtitle = "Artista";
    }

    return GestureDetector(
      onTap: () {
        if (item is Track) {
          // 1. CANCIÓN
          final handler = audioHandler as AudioPlayerHandler;
          handler.playFromPlaylist([item], 0); 
          miniplayerController.animateToHeight(state: PanelState.MAX);
          
        } else if (item is Album) {
          // 2. ÁLBUM
          context.push('/album_detail', extra: item);
          
        } else if (item is Artist) {
          // 3. ARTISTA
          context.push('/artist_detail', extra: item);
        }
      },
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: isCircle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Container(
              height: 120, width: 120,
              decoration: BoxDecoration(
                shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCircle ? null : BorderRadius.circular(8),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl),
                  fit: BoxFit.cover,
                ),
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: isCircle ? TextAlign.center : TextAlign.start,
            ),
            if (!isCircle)
              Text(
                subtitle,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

// Clases auxiliares
enum SectionType { album, track, artist }

class HomeSection {
  final String title;
  final List<dynamic> items;
  final SectionType type;

  HomeSection({required this.title, required this.items, required this.type});
}
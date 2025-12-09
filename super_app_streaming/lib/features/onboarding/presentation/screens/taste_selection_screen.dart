import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:super_app_streaming/core/app_theme.dart';
import 'package:super_app_streaming/features/music/data/repositories/external_music_repository.dart'; 
import 'package:super_app_streaming/features/music/domain/models/artist.dart';
import 'dart:async';

class TasteSelectionScreen extends StatefulWidget {
  const TasteSelectionScreen({super.key});

  @override
  State<TasteSelectionScreen> createState() => _TasteSelectionScreenState();
}

class _TasteSelectionScreenState extends State<TasteSelectionScreen> {
  final Set<String> _selectedArtistIds = {}; 
  final _musicRepo = ExternalMusicRepository();
  
  // Estado para paginación
  final ScrollController _scrollController = ScrollController();
  List<Artist> _artists = [];
  bool _isLoading = true;
  bool _isLoadingMore = false; // Para el spinner de abajo
  int _currentOffset = 0; // Cuántos llevamos cargados (offset)
  
  Timer? _debounce;
  String _lastQuery = "";

  @override
  void initState() {
    super.initState();
    _loadInitialArtists();
    
    // Escuchar el scroll para paginación infinita
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && 
          !_isLoadingMore && _lastQuery.isEmpty) {
        // Solo cargamos más si no estamos buscando (la búsqueda simple no la paginamos en este ejemplo)
        _loadMoreArtists();
      }
    });
  }

  void _loadInitialArtists() async {
    try {
      final artists = await _musicRepo.getTrendingArtists(offset: 0, limit: 30);
      if (mounted) {
        setState(() {
          _artists = artists;
          _currentOffset = artists.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // Cargar siguiente página
  void _loadMoreArtists() async {
    setState(() => _isLoadingMore = true);
    
    try {
      final newArtists = await _musicRepo.getTrendingArtists(offset: _currentOffset, limit: 30);
      
      if (mounted) {
        setState(() {
          // Evitamos duplicados visuales
          final existingIds = _artists.map((e) => e.id).toSet();
          final uniqueNewArtists = newArtists.where((a) => !existingIds.contains(a.id)).toList();
          
          _artists.addAll(uniqueNewArtists);
          _currentOffset += newArtists.length; // Avanzamos el offset
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String query) {
    _lastQuery = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      
      if (query.isEmpty) {
        // Si borra, recargar iniciales
        _loadInitialArtists();
        return;
      }

      // Si busca, usamos la API de búsqueda
      final results = await _musicRepo.searchArtists(query);
      if (mounted) {
        setState(() {
          _artists = results;
          _isLoading = false;
        });
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedArtistIds.contains(id)) {
        _selectedArtistIds.remove(id);
      } else {
        _selectedArtistIds.add(id);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedArtistIds.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Qué te gusta?', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Elige tus artistas favoritos.', style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(height: 16),
                  
                  TextField(
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      hintText: "Buscar artista...",
                      filled: true,
                      fillColor: Colors.grey.shade900,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _artists.isEmpty 
                  ? const Center(child: Text("No se encontraron artistas"))
                  : GridView.builder(
                      controller: _scrollController, // IMPORTANTE: Conectar el controlador
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      // Añadimos 1 al item count si estamos cargando más para mostrar spinner abajo
                      itemCount: _artists.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Si es el último item y estamos cargando, mostramos spinner
                        if (index == _artists.length) {
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        }

                        final artist = _artists[index];
                        final isSelected = _selectedArtistIds.contains(artist.id);

                        return GestureDetector(
                          onTap: () => _toggleSelection(artist.id),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: isSelected ? 90 : 80,
                                width: isSelected ? 90 : 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade800,
                                  image: DecorationImage(
                                    image: NetworkImage(artist.imageUrl),
                                    fit: BoxFit.cover,
                                    colorFilter: isSelected 
                                      ? null 
                                      : const ColorFilter.mode(Colors.black45, BlendMode.darken),
                                  ),
                                  border: isSelected ? Border.all(color: AppTheme.primary, width: 3) : null,
                                ),
                                child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                artist.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : Colors.grey,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: canContinue ? 1.0 : 0.0,
        child: FloatingActionButton.extended(
          onPressed: canContinue 
            ? () async {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mezclando tus favoritos... 🎧')));
                try {
                  final playlist = await _musicRepo.getPersonalizedMix(_selectedArtistIds.toList());
                  if (context.mounted) context.go('/home', extra: playlist); 
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                }
              }
            : null,
          backgroundColor: AppTheme.primary,
          label: Text('LISTO (${_selectedArtistIds.length})'),
          icon: const Icon(Icons.play_arrow),
        ),
      ),
    );
  }
}
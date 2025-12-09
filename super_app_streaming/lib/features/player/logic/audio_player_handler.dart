import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:super_app_streaming/core/utils/audio_resolver.dart';
import 'package:super_app_streaming/core/utils/logger_service.dart';
import 'package:super_app_streaming/features/music/domain/models/track.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  final _audioResolver = AudioResolver();
  int _currentIndex = 0;
  
  // NUEVA VARIABLE: Para saber si estamos en el "limbo" buscando el link
  bool _isResolving = false; 

  AudioPlayerHandler() {
    // 1. Escuchar eventos
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((state) => _broadcastState(_player.playbackEvent));

    // 2. Auto-avance
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  Future<void> playFromPlaylist(List<Track> tracks, int index) async {
    _currentIndex = index;

    // Creamos los items visuales
    final queueItems = tracks.map((track) {
      return MediaItem(
        id: 'resolving_${track.id}',
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

    queue.add(queueItems);
    mediaItem.add(queueItems[index]);

    await _playCurrentIndex();
  }

  Future<void> _playCurrentIndex() async {
    // 1. DETENER LO QUE SUENA INMEDIATAMENTE
    // Esto silencia la canción anterior al instante.
    await _player.stop(); 
    
    // 2. ACTIVAR MODO CARGA
    // Levantamos la bandera y forzamos una actualización de estado.
    // Esto hará que la UI muestre el spinner y ponga el tiempo en 0:00.
    _isResolving = true;
    _broadcastState(_player.playbackEvent); 

    try {
      final currentItem = queue.value[_currentIndex];
      final artist = currentItem.extras?['artist_name'] ?? "";
      final title = currentItem.title;

      logger.i("🔍 Resolviendo audio para: $title - $artist");
      
      // Buscamos el link (esto tarda unos segundos)
      final streamUrl = await _audioResolver.getFullAudioUrl(artist, title);

      // 3. DESACTIVAR MODO CARGA
      // Ya tenemos el link, así que volvemos a la normalidad.
      _isResolving = false;

      if (streamUrl.isNotEmpty) {
        final resolvedItem = currentItem.copyWith(id: streamUrl);
        mediaItem.add(resolvedItem); 

        // Cargar y Reproducir
        await _player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)));
        _player.play();
      } else {
        logger.e("❌ No se encontró URL para: $title");
        // Si falló, actualizamos para quitar el spinner
        _broadcastState(_player.playbackEvent);
      }
    } catch (e) {
      _isResolving = false;
      logger.e("Error reproduciendo: $e");
      _broadcastState(_player.playbackEvent);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_currentIndex + 1 < queue.value.length) {
      _currentIndex++;
      await _playCurrentIndex();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      _currentIndex--;
      await _playCurrentIndex();
    }
  }

  // --- EMISIÓN DE ESTADO INTELIGENTE ---
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final processingState = _player.processingState;

    // TRUCO: Si la bandera _isResolving está activa, MENTIMOS a la UI
    // diciéndole que estamos "cargando" (loading), sin importar lo que diga el player real.
    // Esto asegura que se vea el Spinner y el tiempo 0:00.
    final effectiveProcessingState = _isResolving 
        ? AudioProcessingState.loading 
        : const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[processingState]!;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: effectiveProcessingState,
      playing: playing,
      // Si estamos resolviendo, forzamos la posición a 0:00
      updatePosition: _isResolving ? Duration.zero : _player.position, 
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }
}
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:super_app_streaming/core/utils/audio_resolver.dart';
import 'package:super_app_streaming/core/utils/logger_service.dart';
import 'package:super_app_streaming/features/music/domain/models/track.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  final _audioResolver = AudioResolver(); // Instancia para buscar links de audio
  int _currentIndex = 0;

  AudioPlayerHandler() {
    // 1. Escuchar eventos del player
    _player.playbackEventStream.listen((event) {
      _broadcastState(event);
    });

    // 2. Escuchar cambios de estado (Play/Pause/Buffering)
    _player.playerStateStream.listen((state) {
      _broadcastState(_player.playbackEvent);
    });

    // 3. Auto-avance al terminar canción
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  // --- NUEVA FUNCIÓN PRINCIPAL ---
  // Esta función recibe Tracks normales, actualiza la UI al instante y luego resuelve el audio.
  Future<void> playFromPlaylist(List<Track> tracks, int index) async {
    _currentIndex = index;

    // 1. Convertimos la lista de Tracks a MediaItems con toda la info VISUAL (Metadata)
    // Dejamos el ID temporal 'resolving' para saber que aún no tiene audio real.
    final queueItems = tracks.map((track) {
      return MediaItem(
        id: 'resolving_${track.id}', // ID temporal
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

    // 2. Actualizamos la cola y el ítem actual INMEDIATAMENTE.
    // Esto hace que el MiniPlayer o el PlayerScreen muestren la canción al instante.
    queue.add(queueItems);
    mediaItem.add(queueItems[index]);

    // 3. Iniciamos el proceso de buscar el audio real y reproducir.
    await _playCurrentIndex();
  }

  // Lógica interna para resolver URL y tocar
  Future<void> _playCurrentIndex() async {
    // Obtenemos el item actual de la cola (que tiene metadata pero quizás no URL de audio)
    final currentItem = queue.value[_currentIndex];

    // Notificamos estado 'loading' pero la UI ya tiene foto y título
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.loading,
    ));

    try {
      // 1. Buscamos el link de audio real en segundo plano
      final artist = currentItem.extras?['artist_name'] ?? "";
      final title = currentItem.title;

      logger.i("🔍 Resolviendo audio para: $title - $artist");
      
      // Llamamos a tu AudioResolver
      final streamUrl = await _audioResolver.getFullAudioUrl(artist, title);

      if (streamUrl.isNotEmpty) {
        // 2. Creamos un nuevo MediaItem que SÍ tiene la URL en el ID
        final resolvedItem = currentItem.copyWith(id: streamUrl);
        
        // 3. Actualizamos para que el sistema sepa que ya hay audio
        mediaItem.add(resolvedItem); 

        // 4. Cargamos y reproducimos
        await _player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)));
        _player.play();
      } else {
        logger.e("❌ No se encontró URL para: $title");
        // Opcional: saltar a la siguiente si falla
        // skipToNext(); 
      }
    } catch (e) {
      logger.e("Error reproduciendo: $e");
    }
  }

  // --- CONTROLES ESTÁNDAR ---

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
      // Usamos la lógica interna para resolver la siguiente
      await _playCurrentIndex();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    // Si ya pasaron 3 segundos, reiniciamos la canción actual
    if (_player.position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }
    // Si no, vamos a la anterior
    if (_currentIndex > 0) {
      _currentIndex--;
      await _playCurrentIndex();
    }
  }

  // Función auxiliar para emitir el estado a la UI
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final processingState = _player.processingState;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }
}
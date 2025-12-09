import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:super_app_streaming/core/utils/logger_service.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
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

    // 3. Auto-avance
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  // Carga inicial
  Future<void> loadPlaylist(List<MediaItem> items, int initialIndex) async {
    _currentIndex = initialIndex;
    queue.add(items);
    mediaItem.add(items[initialIndex]);

    final currentUrl = items[initialIndex].id;
    if (currentUrl.isNotEmpty) {
       await playResolvedUrl(currentUrl);
    }
  }

  // Reproducir URL resuelta
  Future<void> playResolvedUrl(String url) async {
    try {
      // Forzar estado de carga VISUAL antes de procesar
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.buffering,
      ));

      // Configurar audio
      final source = AudioSource.uri(Uri.parse(url));
      await _player.setAudioSource(source);
      _player.play();
    } catch (e) {
      logger.e("Error en just_audio: $e");
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
    final q = queue.value;
    if (_currentIndex + 1 < q.length) {
      _currentIndex++;
      _notifySkip(q[_currentIndex]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }
    final q = queue.value;
    if (_currentIndex > 0) {
      _currentIndex--;
      _notifySkip(q[_currentIndex]);
    }
  }

  // Helper para notificar a la UI que cambiamos de canción y debe mostrar carga
  void _notifySkip(MediaItem newItem) {
    // 1. Detener audio actual
    _player.stop(); 
    
    // 2. Actualizar metadata (Título, foto)
    mediaItem.add(newItem);

    // 3. FORZAR estado de Buffering para que salga el círculo de carga
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.buffering,
      playing: true, 
      queueIndex: _currentIndex,
    ));
  }

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
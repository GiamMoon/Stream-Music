import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioManager {
  // MOTOR DOBLE
  late AudioPlayer _playerA;
  late AudioPlayer _playerB;
  
  // ESTADO
  bool _isPlayerAActive = true; // ¿Cuál es el reproductor principal actual?
  double _crossfadeDuration = 6.0; // Segundos de mezcla (Configurable)
  Timer? _faderTimer;

  // STREAMS (Combinamos la data del reproductor activo)
  Stream<PositionData> get positionDataStream => Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _activePlayer.positionStream,
        _activePlayer.durationStream.map((d) => d ?? Duration.zero),
        _activePlayer.bufferedPositionStream,
        (pos, dur, buf) => PositionData(pos, dur, buf ?? Duration.zero),
      );

  Stream<PlayerState> get playerStateStream => _activePlayer.playerStateStream;

  // Getter dinámico para saber cuál usar
  AudioPlayer get _activePlayer => _isPlayerAActive ? _playerA : _playerB;
  AudioPlayer get _inactivePlayer => _isPlayerAActive ? _playerB : _playerA;

  AudioManager() {
    _playerA = AudioPlayer();
    _playerB = AudioPlayer();
    
    // Escuchar el progreso para disparar el crossfade automáticamente
    _playerA.positionStream.listen((pos) => _checkCrossfadeTrigger(pos, _playerA));
    _playerB.positionStream.listen((pos) => _checkCrossfadeTrigger(pos, _playerB));
  }

  // Cargar inicial (Solo carga en el activo)
  Future<void> loadAndPlay(String url) async {
    // Reseteamos volúmenes
    _faderTimer?.cancel();
    _playerA.setVolume(1.0);
    _playerB.setVolume(1.0);
    
    await _activePlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
    _activePlayer.play();
  }

  // LÓGICA CORE DEL CROSSFADE
  // Se llama cada vez que avanza la canción
  void _checkCrossfadeTrigger(Duration position, AudioPlayer player) {
    // Solo si este player es el activo y está sonando
    if (player != _activePlayer || !player.playing) return;
    
    final duration = player.duration;
    if (duration == null) return;

    // Calcular cuánto falta para terminar
    final timeRemaining = duration.inSeconds - position.inSeconds;

    // Si falta menos que el tiempo de crossfade y el otro player está libre...
    // NOTA: En una app real, aquí necesitaríamos la URL de la *siguiente* canción de la playlist.
    // Como simplificación para este demo, simularemos el efecto bajando volumen.
    
    // Para implementar el Crossfade REAL necesitamos una Playlist (Queue).
    // Por ahora, implementaremos el "Fade Out" suave al terminar.
    if (timeRemaining <= _crossfadeDuration && timeRemaining > 0) {
       // Calcular volumen basado en porcentaje restante (Linear Fade)
       // Si faltan 6s (de 6s), vol = 1.0
       // Si falta 0s, vol = 0.0
       double volume = timeRemaining / _crossfadeDuration;
       if (volume < 0) volume = 0;
       if (volume > 1) volume = 1;
       
       player.setVolume(volume);
    }
  }

  // Controles básicos delegados al player activo
  Future<void> play() => _activePlayer.play();
  Future<void> pause() => _activePlayer.pause();
  Future<void> seek(Duration position) => _activePlayer.seek(position);

  void dispose() {
    _faderTimer?.cancel();
    _playerA.dispose();
    _playerB.dispose();
  }
}

class PositionData {
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  PositionData(this.position, this.duration, this.bufferedPosition);
}
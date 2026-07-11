import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioService {
  final Map<String, AudioPlayer> _players = {};
  Timer? _positionTimer;
  bool _isPlaying = false;
  double _masterVolume = 1.0;

  void Function(double position)? onPositionChanged;

  bool get isPlaying => _isPlaying;

  double get masterVolume => _masterVolume;

  set masterVolume(double v) {
    _masterVolume = v.clamp(0.0, 1.0);
    for (final player in _players.values) {
      player.setVolume(_masterVolume);
    }
  }

  Future<void> loadTrack(Track track) async {
    if (track.audioFilePath == null) return;

    final player = AudioPlayer();
    try {
      await player.setFilePath(track.audioFilePath!);
      player.setVolume(track.volume * _masterVolume);
      _players[track.id] = player;

      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          stop();
        }
      });

      player.positionStream.listen((position) {
        onPositionChanged?.call(position.inMilliseconds / 1000.0);
      });
    } catch (e) {
      player.dispose();
      _players.remove(track.id);
    }
  }

  void updateTrackVolume(String trackId, double volume) {
    final player = _players[trackId];
    if (player != null) {
      player.setVolume(volume * _masterVolume);
    }
  }

  void updateMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    for (final player in _players.values) {
      player.setVolume(_masterVolume);
    }
  }

  Future<void> play() async {
    if (_players.isEmpty) return;
    _isPlaying = true;
    for (final player in _players.values) {
      await player.play();
    }
  }

  Future<void> pause() async {
    _isPlaying = false;
    for (final player in _players.values) {
      await player.pause();
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    for (final player in _players.values) {
      await player.stop();
    }
  }

  Future<void> seekTo(double seconds) async {
    final duration = Duration(milliseconds: (seconds * 1000).round());
    for (final player in _players.values) {
      await player.seek(duration);
    }
  }

  void unloadTrack(String trackId) {
    final player = _players.remove(trackId);
    player?.dispose();
  }

  void unloadAll() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    _isPlaying = false;
  }

  void dispose() {
    _positionTimer?.cancel();
    unloadAll();
  }
}

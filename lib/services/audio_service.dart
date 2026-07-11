import 'dart:async';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

class AudioService {
  final Map<String, Player> _players = {};
  bool _isPlaying = false;
  double _masterVolume = 1.0;

  void Function(double position)? onPositionChanged;

  bool get isPlaying => _isPlaying;

  double get masterVolume => _masterVolume;

  set masterVolume(double v) {
    _masterVolume = v.clamp(0.0, 1.0);
    for (final player in _players.values) {
      player.setVolume((_masterVolume * 100).roundToDouble());
    }
  }

  Future<double> loadTrack(Track track) async {
    if (track.audioFilePath == null) return 0;

    final player = Player();
    try {
      final uri = Uri.file(track.audioFilePath!);
      await player.open(Media(uri.toString()), play: false);

      final vol = (track.volume * _masterVolume * 100).roundToDouble();
      await player.setVolume(vol);

      _players[track.id] = player;

      player.stream.completed.listen((completed) {
        if (completed) stop();
      });

      player.stream.position.listen((position) {
        onPositionChanged?.call(position.inMilliseconds / 1000.0);
      });

      return player.state.duration.inMilliseconds / 1000.0;
    } catch (e) {
      player.dispose();
      _players.remove(track.id);
      return 0;
    }
  }

  void updateTrackVolume(String trackId, double volume) {
    final player = _players[trackId];
    if (player != null) {
      player.setVolume((volume * _masterVolume * 100).roundToDouble());
    }
  }

  void updateMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    for (final player in _players.values) {
      player.setVolume((_masterVolume * 100).roundToDouble());
    }
  }

  Future<void> play() async {
    if (_players.isEmpty) return;
    _isPlaying = true;
    for (final player in _players.values) {
      player.play();
    }
  }

  Future<void> pause() async {
    _isPlaying = false;
    for (final player in _players.values) {
      player.pause();
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    for (final player in _players.values) {
      player.stop();
    }
  }

  Future<void> seekTo(double seconds) async {
    final duration = Duration(milliseconds: (seconds * 1000).round());
    for (final player in _players.values) {
      player.seek(duration);
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
    unloadAll();
  }
}

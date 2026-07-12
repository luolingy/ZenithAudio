import 'dart:async';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';
import '../core/utils/logger.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

class _TrackPlayer {
  final Player player;
  StreamSubscription? completedSub;
  StreamSubscription? positionSub;
  StreamSubscription? durationSub;
  bool _disposed = false;

  _TrackPlayer(this.player);

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // Cancel Dart subscriptions (fire-and-forget; isolate teardown is imminent)
    completedSub?.cancel();
    positionSub?.cancel();
    durationSub?.cancel();
    completedSub = null;
    positionSub = null;
    durationSub = null;

    // Stop playback and release native resources synchronously.
    // This ensures media_kit's NativeReferenceHolder removes its entries
    // BEFORE the Dart isolate is torn down by hot restart.
    player.stop();
    player.dispose();
  }
}

class AudioService {
  final Map<String, _TrackPlayer> _players = {};
  bool _isPlaying = false;
  double _masterVolume = 1.0;

  void Function(double position)? onPositionChanged;
  void Function()? onCompleted;

  bool get isPlaying => _isPlaying;

  double get masterVolume => _masterVolume;

  set masterVolume(double v) {
    _masterVolume = v.clamp(0.0, 1.0);
    for (final tp in _players.values) {
      tp.player.setVolume((_masterVolume * 100).roundToDouble());
    }
  }

  DateTime _lastPositionUpdate = DateTime.now();
  static const Duration _positionThrottle = Duration(milliseconds: 33);

  Future<double> loadTrack(Track track) async {
    if (track.audioFilePath == null) return 0;

    final player = Player();
    final tp = _TrackPlayer(player);
    try {
      final uri = Uri.file(track.audioFilePath!);
      await player.open(Media(uri.toString()), play: false);

      final vol = (track.volume * _masterVolume * 100).roundToDouble();
      await player.setVolume(vol);

      _players[track.id] = tp;

      tp.completedSub = player.stream.completed.listen((completed) {
        if (tp._disposed) return;
        if (completed) {
          _isPlaying = false;
          onCompleted?.call();
        }
      });

      tp.positionSub = player.stream.position.listen((position) {
        if (tp._disposed) return;
        final now = DateTime.now();
        if (now.difference(_lastPositionUpdate) < _positionThrottle) return;
        _lastPositionUpdate = now;
        onPositionChanged?.call(position.inMilliseconds / 1000.0);
      });

      double dur = player.state.duration.inMilliseconds / 1000.0;
      if (dur <= 0) {
        try {
          dur = await player.stream.duration
              .firstWhere((d) => d > Duration.zero,
                  orElse: () => Duration.zero)
              .timeout(const Duration(seconds: 5),
                  onTimeout: () => Duration.zero)
              .then((d) => d.inMilliseconds / 1000.0);
        } catch (_) {
          dur = 0;
        }
      }
      AppLogger.d('loadTrack: ${dur.toStringAsFixed(2)}s');
      return dur;
    } catch (e) {
      tp.dispose();
      _players.remove(track.id);
      return 0;
    }
  }

  void updateTrackVolume(String trackId, double volume) {
    final tp = _players[trackId];
    tp?.player.setVolume((volume * _masterVolume * 100).roundToDouble());
  }

  void setPlaybackSpeed(double speed) {
    for (final tp in _players.values) {
      tp.player.setRate(speed);
    }
  }

  void updateMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    for (final tp in _players.values) {
      tp.player.setVolume((_masterVolume * 100).roundToDouble());
    }
  }

  Future<void> play() async {
    if (_players.isEmpty) return;
    _isPlaying = true;
    for (final tp in _players.values) {
      tp.player.play();
    }
  }

  Future<void> pause() async {
    _isPlaying = false;
    for (final tp in _players.values) {
      tp.player.pause();
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    for (final tp in _players.values) {
      tp.player.stop();
    }
  }

  Future<void> seekTo(double seconds) async {
    final duration = Duration(milliseconds: (seconds * 1000).round());
    for (final tp in _players.values) {
      tp.player.seek(duration);
    }
  }

  Future<void> unloadTrack(String trackId) async {
    final tp = _players.remove(trackId);
    tp?.dispose();
  }

  Future<void> unloadAll() async {
    for (final tp in _players.values) {
      tp.dispose();
    }
    _players.clear();
    _isPlaying = false;
  }

  Future<void> dispose() async {
    await unloadAll();
  }
}

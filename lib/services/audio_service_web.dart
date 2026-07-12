import 'dart:async';
import 'dart:html' as html;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';
import '../core/utils/logger.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

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
    for (final p in _players.values) {
      p.element.volume = (_masterVolume * p.volume).toDouble();
    }
  }

  Future<double> loadTrack(Track track) async {
    final audioPath = track.audioFilePath;
    if (audioPath == null) return 0;

    try {
      final element = html.AudioElement()
        ..src = audioPath
        ..preload = 'auto'
        ..volume = (track.volume * _masterVolume).toDouble();

      await element.onCanPlayThrough.first;
      final dur = element.duration.toDouble();

      final tp = _TrackPlayer(element: element, volume: track.volume);

      tp.positionSub = element.onTimeUpdate.listen((_) {
        onPositionChanged?.call(element.currentTime.toDouble());
      });

      tp.endedSub = element.onEnded.listen((_) {
        final allEnded =
            _players.values.every((p) => p.element.ended || p.element.paused);
        if (allEnded) {
          _isPlaying = false;
          onCompleted?.call();
        }
      });

      _players[track.id] = tp;
      AppLogger.d('loadTrack 时长: ${dur.toStringAsFixed(2)}s');
      return dur;
    } catch (e) {
      AppLogger.e('加载音频失败', e);
      return 0;
    }
  }

  void updateTrackVolume(String trackId, double volume) {
    final tp = _players[trackId];
    if (tp != null) {
      tp.volume = volume;
      tp.element.volume = (volume * _masterVolume).toDouble();
    }
  }

  void updateMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    for (final p in _players.values) {
      p.element.volume = (p.volume * _masterVolume).toDouble();
    }
  }

  Future<void> play() async {
    if (_players.isEmpty) return;
    _isPlaying = true;
    for (final p in _players.values) {
      await p.element.play();
    }
  }

  Future<void> pause() async {
    _isPlaying = false;
    for (final p in _players.values) {
      p.element.pause();
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    for (final p in _players.values) {
      p.element.pause();
      p.element.currentTime = 0;
    }
  }

  Future<void> seekTo(double seconds) async {
    for (final p in _players.values) {
      p.element.currentTime = seconds;
    }
  }

  void unloadTrack(String trackId) {
    final tp = _players.remove(trackId);
    if (tp != null) {
      tp.positionSub?.cancel();
      tp.endedSub?.cancel();
      tp.element.pause();
      tp.element.removeAttribute('src');
      tp.element.load();
    }
  }

  void unloadAll() {
    for (final p in _players.values) {
      p.positionSub?.cancel();
      p.endedSub?.cancel();
      p.element.pause();
      p.element.removeAttribute('src');
      p.element.load();
    }
    _players.clear();
    _isPlaying = false;
  }

  void dispose() {
    unloadAll();
  }
}

class _TrackPlayer {
  final html.AudioElement element;
  double volume;
  StreamSubscription<html.Event>? positionSub;
  StreamSubscription<html.Event>? endedSub;

  _TrackPlayer({required this.element, required this.volume});
}

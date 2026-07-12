import 'dart:math';
import 'track.dart';

class Project {
  final String id;
  final String name;
  final List<Track> tracks;
  final double sampleRate;

  final int timeSignatureNumerator;
  final int timeSignatureDenominator;
  final String keySignature;
  final double bpm;
  final double playbackSpeed;

  const Project({
    required this.id,
    required this.name,
    this.tracks = const [],
    this.sampleRate = 44100,
    this.timeSignatureNumerator = 4,
    this.timeSignatureDenominator = 4,
    this.keySignature = 'C',
    this.bpm = 120,
    this.playbackSpeed = 1.0,
  });

  double get duration =>
      tracks.fold<double>(0, (m, t) => max(t.computedDuration, m));

  double get secondsPerBeat => 60.0 / bpm;

  double get beatDuration => secondsPerBeat;

  double get barDuration => secondsPerBeat * timeSignatureNumerator;

  Project copyWith({
    String? id,
    String? name,
    List<Track>? tracks,
    double? sampleRate,
    int? timeSignatureNumerator,
    int? timeSignatureDenominator,
    String? keySignature,
    double? bpm,
    double? playbackSpeed,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      tracks: tracks ?? this.tracks,
      sampleRate: sampleRate ?? this.sampleRate,
      timeSignatureNumerator:
          timeSignatureNumerator ?? this.timeSignatureNumerator,
      timeSignatureDenominator:
          timeSignatureDenominator ?? this.timeSignatureDenominator,
      keySignature: keySignature ?? this.keySignature,
      bpm: bpm ?? this.bpm,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }

  bool get hasSoloTrack => tracks.any((t) => t.isSolo);

  bool shouldTrackPlay(Track track) {
    if (hasSoloTrack) return track.isSolo;
    return !track.isMuted;
  }
}

import 'dart:math';
import 'track.dart';

class Project {
  final String id;
  final String name;
  final List<Track> tracks;
  final double sampleRate;

  const Project({
    required this.id,
    required this.name,
    this.tracks = const [],
    this.sampleRate = 44100,
  });

  double get duration =>
      tracks.fold<double>(0, (m, t) => max(t.computedDuration, m));

  Project copyWith({
    String? id,
    String? name,
    List<Track>? tracks,
    double? sampleRate,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      tracks: tracks ?? this.tracks,
      sampleRate: sampleRate ?? this.sampleRate,
    );
  }

  bool get hasSoloTrack => tracks.any((t) => t.isSolo);

  bool shouldTrackPlay(Track track) {
    if (hasSoloTrack) return track.isSolo;
    return !track.isMuted;
  }
}

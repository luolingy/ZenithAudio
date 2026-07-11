import 'track.dart';

class Project {
  final String id;
  final String name;
  final List<Track> tracks;
  final double sampleRate;
  final double duration;

  const Project({
    required this.id,
    required this.name,
    this.tracks = const [],
    this.sampleRate = 44100,
    this.duration = 0,
  });

  Project copyWith({
    String? id,
    String? name,
    List<Track>? tracks,
    double? sampleRate,
    double? duration,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      tracks: tracks ?? this.tracks,
      sampleRate: sampleRate ?? this.sampleRate,
      duration: duration ?? this.duration,
    );
  }

  bool get hasSoloTrack => tracks.any((t) => t.isSolo);

  bool shouldTrackPlay(Track track) {
    if (hasSoloTrack) return track.isSolo;
    return !track.isMuted;
  }
}

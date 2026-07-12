import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'note.dart';

enum TrackType { audio, instrument }

class Track {
  final String id;
  final String name;
  final TrackType type;
  final String? instrumentName;
  final List<Note> notes;
  final double volume;
  final bool isMuted;
  final bool isSolo;
  final String? audioFilePath;
  final Color color;
  final double duration;

  const Track({
    required this.id,
    required this.name,
    this.type = TrackType.audio,
    this.instrumentName,
    this.notes = const [],
    this.volume = 0.8,
    this.isMuted = false,
    this.isSolo = false,
    this.audioFilePath,
    this.color = AppColors.waveform,
    this.duration = 0,
  });

  double get computedDuration {
    if (type == TrackType.instrument && notes.isNotEmpty) {
      final last = notes.last;
      return last.startTime + last.duration;
    }
    return duration;
  }

  Track copyWith({
    String? id,
    String? name,
    TrackType? type,
    String? instrumentName,
    List<Note>? notes,
    double? volume,
    bool? isMuted,
    bool? isSolo,
    String? audioFilePath,
    Color? color,
    double? duration,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      instrumentName: instrumentName ?? this.instrumentName,
      notes: notes ?? this.notes,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      color: color ?? this.color,
      duration: duration ?? this.duration,
    );
  }

  bool get shouldPlay {
    return !isMuted && volume > 0;
  }
}

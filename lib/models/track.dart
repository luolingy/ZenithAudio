import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class Track {
  final String id;
  final String name;
  final double volume;
  final bool isMuted;
  final bool isSolo;
  final String? audioFilePath;
  final Color color;

  const Track({
    required this.id,
    required this.name,
    this.volume = 0.8,
    this.isMuted = false,
    this.isSolo = false,
    this.audioFilePath,
    this.color = AppColors.waveform,
  });

  Track copyWith({
    String? id,
    String? name,
    double? volume,
    bool? isMuted,
    bool? isSolo,
    String? audioFilePath,
    Color? color,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      color: color ?? this.color,
    );
  }

  bool get shouldPlay {
    return !isMuted && volume > 0;
  }
}

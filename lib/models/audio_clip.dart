import 'dart:typed_data';

class Selection {
  double startSec;
  double endSec;

  Selection({required this.startSec, required this.endSec});

  double get duration => endSec - startSec;
  bool get isValid => duration > 0;

  Selection copyWith({double? startSec, double? endSec}) =>
      Selection(startSec: startSec ?? this.startSec, endSec: endSec ?? this.endSec);
}

class WaveformGenParams {
  final String type; // 'sine', 'square', 'sawtooth', 'triangle', 'pulse', 'whiteNoise', 'pinkNoise', 'brownNoise'
  final double frequency;
  final double amplitude;
  final double? dutyCycle;
  final int? seed;

  const WaveformGenParams({
    required this.type,
    required this.frequency,
    this.amplitude = 0.8,
    this.dutyCycle,
    this.seed,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'frequency': frequency,
    'amplitude': amplitude,
    if (dutyCycle != null) 'dutyCycle': dutyCycle,
    if (seed != null) 'seed': seed,
  };

  factory WaveformGenParams.fromJson(Map<String, dynamic> json) => WaveformGenParams(
    type: json['type'] as String,
    frequency: (json['frequency'] as num).toDouble(),
    amplitude: (json['amplitude'] as num?)?.toDouble() ?? 0.8,
    dutyCycle: (json['dutyCycle'] as num?)?.toDouble(),
    seed: json['seed'] as int?,
  );
}

class AudioClip {
  final Float64List samples;
  final int sampleRate;
  final String? sourceFile;
  final WaveformGenParams? genParams;
  Selection? selection;

  AudioClip({
    required this.samples,
    this.sampleRate = 44100,
    this.sourceFile,
    this.genParams,
    this.selection,
  });

  double get duration => samples.length / sampleRate;

  /// Extract selected region as a new clip.
  AudioClip? get selectedRegion {
    if (selection == null || !selection!.isValid) return null;
    final startSample = (selection!.startSec * sampleRate).round();
    final endSample = (selection!.endSec * sampleRate).round().clamp(0, samples.length);
    final regionSamples = Float64List(endSample - startSample);
    for (int i = 0; i < regionSamples.length; i++) {
      regionSamples[i] = samples[startSample + i];
    }
    return AudioClip(samples: regionSamples, sampleRate: sampleRate, genParams: genParams);
  }
}

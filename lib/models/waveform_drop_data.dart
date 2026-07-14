class WaveformDropData {
  final String type;
  final double frequency;
  final double duration;
  final double amplitude;
  final double dutyCycle;

  const WaveformDropData({
    required this.type,
    this.frequency = 440,
    this.duration = 2.0,
    this.amplitude = 0.8,
    this.dutyCycle = 0.5,
  });

  bool get isNoiseType => type.contains('Noise');
  bool get isPulseType => type == 'pulse' || type == 'square';
}

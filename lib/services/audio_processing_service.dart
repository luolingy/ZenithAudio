import 'dart:math';
import 'dart:typed_data';

class AudioProcessingService {
  /// Apply gain in dB (positive = amplify, negative = attenuate).
  static Float64List applyGain(Float64List samples, double gainDB) {
    final factor = pow(10, gainDB / 20).toDouble();
    final result = Float64List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      result[i] = samples[i] * factor;
    }
    return result;
  }

  /// Normalize peak amplitude to [target] (0–1).
  static Float64List normalizePeak(Float64List samples, {double target = 0.95}) {
    double maxAmp = 0;
    for (final s in samples) {
      final a = s.abs();
      if (a > maxAmp) maxAmp = a;
    }
    if (maxAmp <= 0) return Float64List.fromList(samples);
    final scale = target / maxAmp;
    final result = Float64List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      result[i] = samples[i] * scale;
    }
    return result;
  }

  /// Reverse the audio.
  static Float64List reverse(Float64List samples) {
    final result = Float64List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      result[i] = samples[samples.length - 1 - i];
    }
    return result;
  }

  /// Linear fade-in over [duration] seconds.
  static Float64List fadeIn(Float64List samples, double duration, int sampleRate) {
    final fadeSamples = (duration * sampleRate).round().clamp(0, samples.length);
    final result = Float64List.fromList(samples);
    for (int i = 0; i < fadeSamples; i++) {
      result[i] *= i / fadeSamples;
    }
    return result;
  }

  /// Linear fade-out over [duration] seconds.
  static Float64List fadeOut(Float64List samples, double duration, int sampleRate) {
    final fadeSamples = (duration * sampleRate).round().clamp(0, samples.length);
    final result = Float64List.fromList(samples);
    final start = samples.length - fadeSamples;
    for (int i = 0; i < fadeSamples; i++) {
      result[start + i] *= (fadeSamples - i) / fadeSamples;
    }
    return result;
  }

  /// Remove DC offset (subtract mean).
  static Float64List removeDCOffset(Float64List samples) {
    double sum = 0;
    for (final s in samples) sum += s;
    final mean = sum / samples.length;
    if (mean.abs() < 1e-10) return Float64List.fromList(samples);
    final result = Float64List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      result[i] = samples[i] - mean;
    }
    return result;
  }

  /// Simple hard-clip distortion.
  static Float64List distort(Float64List samples, double threshold) {
    final result = Float64List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      result[i] = samples[i].clamp(-threshold, threshold);
    }
    return result;
  }

  /// Simple feedback delay.
  static Float64List delay(Float64List samples, int sampleRate,
      {double delayTime = 0.3, double feedback = 0.4, double mix = 0.5}) {
    final delaySamples = (delayTime * sampleRate).round();
    if (delaySamples <= 0) return Float64List.fromList(samples);
    final result = Float64List(samples.length + delaySamples);
    for (int i = 0; i < samples.length; i++) {
      result[i] += samples[i] * (1 - mix);
      result[i + delaySamples] += samples[i] * mix + result[i] * feedback;
    }
    return result.sublist(0, samples.length) as Float64List;
  }

  /// Simple Schroeder-style reverb (comb filters + all-pass).
  static Float64List reverb(Float64List samples, int sampleRate,
      {double decay = 0.5, double mix = 0.3}) {
    final combDelays = [0.029, 0.037, 0.047, 0.061];
    final allpassDelays = [0.005, 0.0017];
    final result = Float64List(samples.length);

    for (final cd in combDelays) {
      final dSamples = (cd * sampleRate).round();
      if (dSamples <= 0) continue;
      final comb = Float64List(samples.length);
      for (int i = 0; i < samples.length; i++) {
        comb[i] = samples[i] + (i >= dSamples ? comb[i - dSamples] * decay : 0);
      }
      for (int i = 0; i < samples.length; i++) {
        result[i] += comb[i];
      }
    }
    // Average combs
    for (int i = 0; i < samples.length; i++) {
      result[i] /= combDelays.length;
    }

    // All-pass filters
    for (final ad in allpassDelays) {
      final dSamples = (ad * sampleRate).round();
      if (dSamples <= 0) continue;
      final ap = Float64List(samples.length);
      final gain = 0.7;
      for (int i = 0; i < samples.length; i++) {
        final input = result[i];
        ap[i] = input * -gain + (i >= dSamples ? ap[i - dSamples] : 0);
        result[i] = ap[i] + input * gain;
      }
    }

    // Mix dry/wet
    for (int i = 0; i < samples.length; i++) {
      result[i] = samples[i] * (1 - mix) + result[i] * mix;
    }
    return result;
  }
}

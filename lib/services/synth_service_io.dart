import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../core/utils/logger.dart';

/// Synthesizes instrument tracks to WAV audio files on desktop.
class SynthService {
  static const _sampleRate = 44100;
  static const _uuid = Uuid();

  /// Generate a WAV file from a list of MIDI [notes] for the given instrument.
  ///
  /// Returns the file path to the generated WAV and the total duration in seconds.
  Future<({String path, double duration})> renderToFile({
    required List<Note> notes,
    required String instrumentName,
  }) async {
    if (notes.isEmpty) {
      AppLogger.w('SynthService: no notes to render');
      return (path: '', duration: 0.0);
    }

    final tempDir = await getTemporaryDirectory();
    final totalDuration = _computeDuration(notes);
    final numSamples = (_sampleRate * totalDuration).ceil();

    // Generate float PCM buffer.
    final buffer = Float64List(numSamples);
    _renderNotes(notes, instrumentName, buffer, numSamples);

    // Normalize to avoid clipping.
    _normalize(buffer);

    // Convert to 16-bit PCM and write WAV.
    final wavBytes = _encodeWav(buffer, numSamples);
    final filePath = '${tempDir.path}/synth_${_uuid.v4()}.wav';
    await File(filePath).writeAsBytes(wavBytes);

    AppLogger.d('SynthService: rendered ${notes.length} notes to $filePath (${totalDuration.toStringAsFixed(2)}s)');
    return (path: filePath, duration: totalDuration);
  }

  double _computeDuration(List<Note> notes) {
    double end = 0;
    for (final n in notes) {
      final e = n.startTime + n.duration;
      if (e > end) end = e;
    }
    // Add a small silence at the end.
    return end + 0.5;
  }

  void _renderNotes(List<Note> notes, String instrumentName, Float64List buffer, int numSamples) {
    for (final note in notes) {
      final startSample = (note.startTime * _sampleRate).round();
      final durSamples = (note.duration * _sampleRate).round();
      if (startSample >= numSamples) break;

      final endSample = (startSample + durSamples).clamp(0, numSamples);
      final freq = _midiToFreq(note.pitch);
      final velocityFactor = note.velocity / 127.0;

      for (int i = startSample; i < endSample; i++) {
        final t = (i - startSample) / _sampleRate;
        final envelope = _getEnvelope(t, note.duration, instrumentName, note.velocity);
        final sample = _synthSample(t, freq, instrumentName) * envelope * velocityFactor;
        buffer[i] += sample;
      }
    }
  }

  double _midiToFreq(int pitch) => 440 * pow(2, (pitch - 69) / 12).toDouble();

  /// ADSR envelope.
  double _getEnvelope(double t, double dur, String instrument, int velocity) {
    // Piano-like: fast attack, natural decay
    if (instrument == 'piano') {
      const attack = 0.005;
      const decay = 0.3;
      final sustain = 0.3;
      const release = 0.1;
      final rStart = dur - release;

      if (t < attack) return t / attack;
      if (t < attack + decay) return 1.0 - (1.0 - sustain) * ((t - attack) / decay);
      if (t < rStart) return sustain;
      return sustain * (1.0 - (t - rStart) / release);
    }

    // Strings: slower attack, more sustain
    {
      const attack = 0.05;
      const decay = 0.2;
      final sustain = 0.8;
      const release = 0.3;
      final rStart = dur - release;

      if (t < attack) return t / attack;
      if (t < attack + decay) return 1.0 - (1.0 - sustain) * ((t - attack) / decay);
      if (t < rStart) return sustain;
      return sustain * (1.0 - (t - rStart) / release);
    }
  }

  /// Generate a single sample for the given instrument and frequency.
  double _synthSample(double t, double freq, String instrument) {
    if (instrument == 'piano') {
      // Piano: fundamental + bright harmonics with faster decay on higher harmonics.
      double s = 0;
      for (int h = 1; h <= 6; h++) {
        final amp = pow(0.6, h - 1).toDouble() * (h == 1 ? 0.8 : 0.3 / h);
        s += sin(2 * pi * freq * h * t) * amp;
      }
      return s;
    }

    // Strings: sawtooth-like, richer harmonics.
    double s = 0;
    for (int h = 1; h <= 8; h++) {
      final amp = (1.0 / h) * pow(0.95, h - 1).toDouble();
      s += sin(2 * pi * freq * h * t) * amp;
    }
    return s;
  }

  void _normalize(Float64List buffer) {
    double maxAmp = 0;
    for (final s in buffer) {
      final abs = s.abs();
      if (abs > maxAmp) maxAmp = abs;
    }
    if (maxAmp > 0 && maxAmp > 0.95) {
      final scale = 0.95 / maxAmp;
      for (int i = 0; i < buffer.length; i++) {
        buffer[i] *= scale;
      }
    }
  }

  /// Encode float PCM (range -1..1) to 16-bit mono WAV.
  Uint8List _encodeWav(Float64List buffer, int numSamples) {
    final bytesPerSample = 2;
    final dataSize = numSamples * bytesPerSample;
    final fileSize = 44 + dataSize;
    final result = DataWriter(fileSize);

    // RIFF header
    result.writeString('RIFF');
    result.writeInt32(fileSize - 8);
    result.writeString('WAVE');

    // fmt chunk
    result.writeString('fmt ');
    result.writeInt32(16);        // subchunk size
    result.writeInt16(1);         // PCM
    result.writeInt16(1);         // mono
    result.writeInt32(_sampleRate);
    result.writeInt32(_sampleRate * bytesPerSample); // byte rate
    result.writeInt16(bytesPerSample);  // block align
    result.writeInt16(16);        // bits per sample

    // data chunk
    result.writeString('data');
    result.writeInt32(dataSize);
    for (int i = 0; i < numSamples; i++) {
      final clamped = buffer[i].clamp(-1.0, 1.0);
      final sample = (clamped * 32767).round().clamp(-32768, 32767);
      result.writeInt16(sample);
    }

    return result.bytes;
  }
}

/// Helper to write binary data.
class DataWriter {
  final List<int> _data;
  int _offset = 0;

  DataWriter(int size) : _data = List.filled(size, 0);

  Uint8List get bytes => Uint8List.fromList(_data);

  void writeString(String s) {
    for (int i = 0; i < s.length; i++) {
      _data[_offset++] = s.codeUnitAt(i);
    }
  }

  void writeInt32(int value) {
    _data[_offset++] = value & 0xFF;
    _data[_offset++] = (value >> 8) & 0xFF;
    _data[_offset++] = (value >> 16) & 0xFF;
    _data[_offset++] = (value >> 24) & 0xFF;
  }

  void writeInt16(int value) {
    _data[_offset++] = value & 0xFF;
    _data[_offset++] = (value >> 8) & 0xFF;
  }
}

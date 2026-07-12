import 'dart:math';
import 'package:flutter/material.dart';

enum InstrumentCategory { keyboard, string, wind, synth, percussion }

class InstrumentPreset {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final InstrumentCategory category;
  final int programNumber;

  // ── Synthesis parameters ──
  final List<double> harmonics;      // amplitude for harmonics 1-16
  final double attack;               // seconds
  final double decay;                // seconds
  final double sustain;              // 0-1 level
  final double release;              // seconds
  final double detuneCents;          // dual-oscillator detune (0 = none)
  final double noiseAttack;          // noise burst amplitude (0 = none)
  final double brightnessFactor;     // velocity brightness scaling

  const InstrumentPreset({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = Icons.music_note_outlined,
    this.category = InstrumentCategory.synth,
    required this.programNumber,
    required this.harmonics,
    this.attack = 0.01,
    this.decay = 0.2,
    this.sustain = 0.7,
    this.release = 0.1,
    this.detuneCents = 0,
    this.noiseAttack = 0,
    this.brightnessFactor = 0.3,
  });

  static const List<InstrumentPreset> presets = [
    // ── Keyboards ──
    InstrumentPreset(
      id: 'piano',
      name: 'Acoustic Grand Piano',
      description: 'Rich, dynamic grand piano',
      icon: Icons.piano,
      category: InstrumentCategory.keyboard,
      programNumber: 0,
      harmonics: [1.0, 0.8, 0.45, 0.30, 0.18, 0.10, 0.06, 0.03],
      attack: 0.003, decay: 0.4, sustain: 0.25, release: 0.15,
      detuneCents: 0.3, noiseAttack: 0.15, brightnessFactor: 0.5,
    ),
    InstrumentPreset(
      id: 'bright_piano',
      name: 'Bright Acoustic Piano',
      description: 'Bright, cutting piano tone',
      icon: Icons.piano,
      category: InstrumentCategory.keyboard,
      programNumber: 1,
      harmonics: [1.0, 0.9, 0.6, 0.45, 0.30, 0.20, 0.12, 0.08],
      attack: 0.002, decay: 0.35, sustain: 0.20, release: 0.12,
      detuneCents: 0.4, noiseAttack: 0.18, brightnessFactor: 0.6,
    ),
    InstrumentPreset(
      id: 'organ',
      name: 'Church Organ',
      description: 'Full, sustaining pipe organ',
      icon: Icons.toc,
      category: InstrumentCategory.keyboard,
      programNumber: 19,
      harmonics: [1.0, 0.5, 0.8, 0.3, 0.6, 0.2, 0.4, 0.1],
      attack: 0.04, decay: 0.05, sustain: 0.95, release: 0.2,
      detuneCents: 1.0, noiseAttack: 0, brightnessFactor: 0.2,
    ),
    InstrumentPreset(
      id: 'accordion',
      name: 'Accordion',
      description: 'Reedy, expressive accordion',
      icon: Icons.toc,
      category: InstrumentCategory.keyboard,
      programNumber: 21,
      harmonics: [1.0, 0.6, 0.9, 0.4, 0.5, 0.25, 0.2, 0.1],
      attack: 0.01, decay: 0.1, sustain: 0.85, release: 0.05,
      detuneCents: 2.0, noiseAttack: 0, brightnessFactor: 0.3,
    ),

    // ── Strings ──
    InstrumentPreset(
      id: 'guitar',
      name: 'Acoustic Guitar (nylon)',
      description: 'Warm nylon-string guitar',
      icon: Icons.music_note_outlined,
      category: InstrumentCategory.string,
      programNumber: 24,
      harmonics: [1.0, 0.7, 0.3, 0.15, 0.08, 0.04, 0.02, 0.01],
      attack: 0.002, decay: 0.15, sustain: 0.6, release: 0.05,
      detuneCents: 0.5, noiseAttack: 0.12, brightnessFactor: 0.4,
    ),
    InstrumentPreset(
      id: 'steel_guitar',
      name: 'Acoustic Guitar (steel)',
      description: 'Bright steel-string acoustic',
      icon: Icons.music_note_outlined,
      category: InstrumentCategory.string,
      programNumber: 25,
      harmonics: [1.0, 0.8, 0.4, 0.20, 0.12, 0.06, 0.04, 0.02],
      attack: 0.001, decay: 0.12, sustain: 0.55, release: 0.04,
      detuneCents: 0.6, noiseAttack: 0.15, brightnessFactor: 0.5,
    ),
    InstrumentPreset(
      id: 'strings',
      name: 'String Ensemble',
      description: 'Lush, sustaining strings',
      icon: Icons.audiotrack,
      category: InstrumentCategory.string,
      programNumber: 48,
      harmonics: [1.0, 0.5, 0.35, 0.25, 0.18, 0.12, 0.08, 0.05],
      attack: 0.08, decay: 0.2, sustain: 0.85, release: 0.4,
      detuneCents: 3.0, noiseAttack: 0, brightnessFactor: 0.25,
    ),
    InstrumentPreset(
      id: 'pizzicato',
      name: 'Pizzicato Strings',
      description: 'Plucked, short strings',
      icon: Icons.audiotrack,
      category: InstrumentCategory.string,
      programNumber: 45,
      harmonics: [1.0, 0.6, 0.3, 0.15, 0.08, 0.04, 0.02, 0.01],
      attack: 0.001, decay: 0.08, sustain: 0, release: 0.02,
      detuneCents: 0.2, noiseAttack: 0.08, brightnessFactor: 0.3,
    ),

    // ── Bass ──
    InstrumentPreset(
      id: 'bass',
      name: 'Acoustic Bass',
      description: 'Warm upright bass',
      icon: Icons.music_note_outlined,
      category: InstrumentCategory.string,
      programNumber: 32,
      harmonics: [1.0, 0.6, 0.3, 0.12, 0.06, 0.03, 0.015, 0.008],
      attack: 0.005, decay: 0.15, sustain: 0.6, release: 0.08,
      detuneCents: 0.4, noiseAttack: 0.08, brightnessFactor: 0.3,
    ),
    InstrumentPreset(
      id: 'electric_bass',
      name: 'Electric Bass (finger)',
      description: 'Deep, punchy electric bass',
      icon: Icons.music_note_outlined,
      category: InstrumentCategory.string,
      programNumber: 33,
      harmonics: [1.0, 0.7, 0.35, 0.18, 0.10, 0.05, 0.025, 0.012],
      attack: 0.003, decay: 0.12, sustain: 0.65, release: 0.06,
      detuneCents: 0.5, noiseAttack: 0.10, brightnessFactor: 0.35,
    ),

    // ── Brass / Wind ──
    InstrumentPreset(
      id: 'brass',
      name: 'Brass Section',
      description: 'Bold, powerful brass ensemble',
      icon: Icons.music_note_outlined,
      category: InstrumentCategory.wind,
      programNumber: 61,
      harmonics: [1.0, 0.8, 0.6, 0.45, 0.3, 0.2, 0.12, 0.08],
      attack: 0.02, decay: 0.15, sustain: 0.85, release: 0.2,
      detuneCents: 1.5, noiseAttack: 0.05, brightnessFactor: 0.4,
    ),
    InstrumentPreset(
      id: 'trumpet',
      name: 'Trumpet',
      description: 'Bright, piercing trumpet',
      icon: Icons.music_note_outlined,
      category: InstrumentCategory.wind,
      programNumber: 56,
      harmonics: [1.0, 0.9, 0.7, 0.55, 0.4, 0.28, 0.18, 0.10],
      attack: 0.01, decay: 0.1, sustain: 0.9, release: 0.15,
      detuneCents: 0.5, noiseAttack: 0.04, brightnessFactor: 0.45,
    ),

    // ── Synth ──
    InstrumentPreset(
      id: 'synth',
      name: 'Synth Lead',
      description: 'Pulsing, cutting synth lead',
      icon: Icons.electric_bolt,
      category: InstrumentCategory.synth,
      programNumber: 80,
      harmonics: [1.0, 0.4, 0.6, 0.2, 0.4, 0.1, 0.2, 0.05],
      attack: 0.005, decay: 0.1, sustain: 0.9, release: 0.05,
      detuneCents: 1.5, noiseAttack: 0, brightnessFactor: 0.2,
    ),
    InstrumentPreset(
      id: 'pad',
      name: 'Synth Pad',
      description: 'Warm, evolving synth pad',
      icon: Icons.waves,
      category: InstrumentCategory.synth,
      programNumber: 88,
      harmonics: [1.0, 0.3, 0.5, 0.2, 0.35, 0.15, 0.25, 0.1],
      attack: 0.3, decay: 0.3, sustain: 0.9, release: 0.8,
      detuneCents: 5.0, noiseAttack: 0, brightnessFactor: 0.15,
    ),
    InstrumentPreset(
      id: 'warm_pad',
      name: 'Warm Pad',
      description: 'Soft, warm analog pad',
      icon: Icons.waves,
      category: InstrumentCategory.synth,
      programNumber: 89,
      harmonics: [1.0, 0.4, 0.2, 0.1, 0.05, 0.025, 0.012, 0.006],
      attack: 0.2, decay: 0.2, sustain: 0.95, release: 0.6,
      detuneCents: 4.0, noiseAttack: 0, brightnessFactor: 0.1,
    ),
  ];

  static InstrumentPreset fromId(String id) =>
      presets.firstWhere((p) => p.id == id);

  double synthSample(double t, double freq, int velocity) {
    // Velocity → brightness: add extra harmonic drive at high velocity
    final vel = velocity / 127.0;
    final bright = brightnessFactor * vel;

    // Main oscillator
    double s = 0;
    for (int h = 0; h < harmonics.length; h++) {
      final amp = harmonics[h] + (h > 0 ? bright * (0.5 / h) : 0);
      s += sin(2 * pi * freq * (h + 1) * t) * amp;
    }

    // Detuned oscillator (if enabled)
    if (detuneCents > 0) {
      final detuneRatio = pow(2, detuneCents / 1200).toDouble();
      double s2 = 0;
      for (int h = 0; h < harmonics.length; h++) {
        final amp = harmonics[h] * 0.4;
        s2 += sin(2 * pi * freq * detuneRatio * (h + 1) * t) * amp;
      }
      s += s2;
    }

    // Noise attack transient
    if (noiseAttack > 0) {
      final noise = (Random().nextDouble() * 2 - 1) * noiseAttack * exp(-t * 80);
      s += noise;
    }

    return s * 0.6; // master level
  }

  double getEnvelope(double t, double dur, int velocity) {
    final rStart = dur - release;
    final vel = velocity / 127.0;
    // Velocity affects attack speed slightly
    final att = attack * (1.0 - vel * 0.3);

    if (t < att) return (t / att) * vel;
    if (t < att + decay) return vel - (vel - sustain * vel) * ((t - att) / decay);
    if (t < rStart) return sustain * vel;
    return (sustain * vel) * max(0.0, 1.0 - (t - rStart) / release);
  }
}

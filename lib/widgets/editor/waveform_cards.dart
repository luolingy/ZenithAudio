import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/waveform_generator.dart';

class _WaveformCardData {
  final String label;
  final IconData icon;
  final Float64List Function() generator;

  const _WaveformCardData({
    required this.label,
    required this.icon,
    required this.generator,
  });
}

class WaveformCards extends StatelessWidget {
  final void Function(Float64List samples) onWaveformDropped;

  const WaveformCards({super.key, required this.onWaveformDropped});

  static final _cards = [
    _WaveformCardData(
      label: 'Sine',
      icon: Icons.waves,
      generator: () => WaveformGenerator.sine(440, 2.0, amplitude: 0.8),
    ),
    _WaveformCardData(
      label: 'Square',
      icon: Icons.show_chart,
      generator: () => WaveformGenerator.square(440, 2.0, amplitude: 0.8),
    ),
    _WaveformCardData(
      label: 'Sawtooth',
      icon: Icons.show_chart,
      generator: () => WaveformGenerator.sawtooth(440, 2.0, amplitude: 0.8),
    ),
    _WaveformCardData(
      label: 'Triangle',
      icon: Icons.show_chart,
      generator: () => WaveformGenerator.triangle(440, 2.0, amplitude: 0.8),
    ),
    _WaveformCardData(
      label: 'White\nNoise',
      icon: Icons.graphic_eq,
      generator: () => WaveformGenerator.whiteNoise(2.0, amplitude: 0.6),
    ),
    _WaveformCardData(
      label: 'Pink\nNoise',
      icon: Icons.graphic_eq,
      generator: () => WaveformGenerator.pinkNoise(2.0, amplitude: 0.6),
    ),
    _WaveformCardData(
      label: 'Brown\nNoise',
      icon: Icons.graphic_eq,
      generator: () => WaveformGenerator.brownNoise(2.0, amplitude: 0.6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(left: BorderSide(color: cs.outlineVariant.withAlpha(77))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
            child: Text(
              'WAVES',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              children: _cards.map((card) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _WaveformCard(card: card, onWaveformDropped: onWaveformDropped),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformCard extends StatelessWidget {
  final _WaveformCardData card;
  final void Function(Float64List samples) onWaveformDropped;

  const _WaveformCard({
    required this.card,
    required this.onWaveformDropped,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final child = Container(
      height: 56,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withAlpha(60)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(card.icon, size: 16, color: cs.primary),
          const SizedBox(height: 3),
          Text(
            card.label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8, color: cs.onSurfaceVariant, height: 1.2),
          ),
        ],
      ),
    );

    return LongPressDraggable<Float64List>(
      data: card.generator(),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 80,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(card.icon, size: 18, color: cs.onPrimaryContainer),
                const SizedBox(height: 3),
                Text(
                  card.label.replaceAll('\n', ' '),
                  style: TextStyle(fontSize: 9, color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      onDragEnd: (details) {
        if (details.wasAccepted) return;
      },
      child: child,
    );
  }
}

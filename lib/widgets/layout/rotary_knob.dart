import 'dart:math' as math;
import 'package:flutter/material.dart';

class RotaryKnob extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double size;
  final Color? activeColor;
  final Color? trackColor;
  final String? label;

  const RotaryKnob({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.size = 20,
    this.activeColor,
    this.trackColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final actColor = activeColor ?? cs.primary;
    final trkColor = trackColor ?? cs.surfaceContainerHighest;
    final frac = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: (details) {
        final delta = details.delta.dy;
        final step = (max - min) / 200;
        final newVal = (value - delta * step).clamp(min, max);
        onChanged(newVal);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _KnobPainter(
            fraction: frac,
            activeColor: actColor,
            trackColor: trkColor,
          ),
        ),
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double fraction;
  final Color activeColor;
  final Color trackColor;

  _KnobPainter({
    required this.fraction,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    final startAngle = -math.pi * 0.75;
    final sweepAngle = math.pi * 1.5;

    // Track arc
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * fraction,
      false,
      activePaint,
    );

    // Center dot
    canvas.drawCircle(center, 1.5, Paint()..color = activeColor);
  }

  @override
  bool shouldRepaint(_KnobPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.activeColor != activeColor;
}

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/theme_colors.dart';

class TimelineRuler extends StatelessWidget {
  final double duration;
  final double pixelsPerSecond;
  final double currentPosition;
  final void Function(double seconds)? onSeek;
  final double bpm;
  final int timeSignatureNumerator;

  const TimelineRuler({
    super.key,
    this.duration = 60,
    this.pixelsPerSecond = 50,
    this.currentPosition = 0,
    this.onSeek,
    this.bpm = 120,
    this.timeSignatureNumerator = 4,
  });

  @override
  Widget build(BuildContext context) {
    final totalWidth = duration * pixelsPerSecond;
    final cs = Theme.of(context).colorScheme;
    final beatSec = 60.0 / bpm;
    final barSec = beatSec * timeSignatureNumerator;

    return SizedBox(
      height: AppConstants.timelineHeight,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
              ),
            ),
            child: ClipRect(
              child: CustomPaint(
                size: Size(totalWidth, AppConstants.timelineHeight),
                painter: _RulerPainter(
                  duration,
                  pixelsPerSecond,
                  barSec,
                  beatSec,
                  Theme.of(context).dividerColor,
                  context.outline,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                final sec = (details.localPosition.dx / pixelsPerSecond)
                    .clamp(0, duration) as double;
                onSeek?.call(sec);
              },
              onHorizontalDragUpdate: (details) {
                final x = details.localPosition.dx.clamp(0, totalWidth) as double;
                final sec = (x / pixelsPerSecond).clamp(0, duration) as double;
                onSeek?.call(sec);
              },
            ),
          ),
          Positioned(
            left: currentPosition * pixelsPerSecond - 1,
            top: 0, bottom: 0,
            child: Container(width: 2, color: AppColors.playhead),
          ),
        ],
      ),
    );
  }
}

String _formatBarsBeats(double seconds, double barSec, double beatSec) {
  if (barSec <= 0 || beatSec <= 0) return '00.00.00';
  final totalBeats = seconds / beatSec;
  final bar = (totalBeats / 4).floor() + 1;
  final beat = (totalBeats % 4).floor() + 1;
  final tick = ((seconds % beatSec) / beatSec * 96).floor().toString().padLeft(2, '0');
  return '${bar.toString().padLeft(2, '0')}.${beat.toString().padLeft(2, '0')}.$tick';
}

class _RulerPainter extends CustomPainter {
  final double duration;
  final double pixelsPerSecond;
  final double barSec;
  final double beatSec;
  final Color borderColor;
  final Color textDimColor;

  _RulerPainter(
    this.duration,
    this.pixelsPerSecond,
    this.barSec,
    this.beatSec,
    this.borderColor,
    this.textDimColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 0.5;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (double t = 0; t <= duration; t += beatSec) {
      if (t > duration) break;
      final x = t * pixelsPerSecond;
      final isBar = (t / barSec).round() * barSec == t;
      final tickHeight = isBar ? 14.0 : 8.0;

      paint.strokeWidth = isBar ? 1.0 : 0.5;
      paint.color = isBar ? textDimColor : borderColor;

      canvas.drawLine(Offset(x, size.height - tickHeight), Offset(x, size.height), paint);

      if (isBar) {
        textPainter.text = TextSpan(
          text: _formatBarsBeats(t, barSec, beatSec),
          style: TextStyle(color: textDimColor, fontSize: 9),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 3, 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.duration != duration ||
      oldDelegate.pixelsPerSecond != pixelsPerSecond ||
      oldDelegate.barSec != barSec ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.textDimColor != textDimColor;
}

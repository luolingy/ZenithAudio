import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/theme_colors.dart';

class TimelineRuler extends StatelessWidget {
  final double duration;
  final double pixelsPerSecond;
  final double currentPosition;

  const TimelineRuler({
    super.key,
    this.duration = 60,
    this.pixelsPerSecond = 50,
    this.currentPosition = 0,
  });

  @override
  Widget build(BuildContext context) {
    final totalWidth = duration * pixelsPerSecond;
    final cs = Theme.of(context).colorScheme;

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
                  Theme.of(context).dividerColor,
                  context.textDim,
                ),
              ),
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

class _RulerPainter extends CustomPainter {
  final double duration;
  final double pixelsPerSecond;
  final Color borderColor;
  final Color textDimColor;

  _RulerPainter(this.duration, this.pixelsPerSecond, this.borderColor, this.textDimColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 0.5;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    double majorInterval;
    double minorInterval;
    final pxPerSec = pixelsPerSecond;

    if (pxPerSec > 200) {
      majorInterval = 1;
      minorInterval = 0.2;
    } else if (pxPerSec > 80) {
      majorInterval = 5;
      minorInterval = 1;
    } else if (pxPerSec > 30) {
      majorInterval = 10;
      minorInterval = 5;
    } else {
      majorInterval = 30;
      minorInterval = 10;
    }

    for (double t = 0; t <= duration; t += minorInterval) {
      final x = t * pixelsPerSecond;
      final isMajor = t % majorInterval == 0;
      final tickHeight = isMajor ? 12.0 : 6.0;

      paint.strokeWidth = isMajor ? 1.0 : 0.5;
      paint.color = isMajor ? textDimColor : borderColor;

      canvas.drawLine(Offset(x, size.height - tickHeight), Offset(x, size.height), paint);

      if (isMajor) {
        final minutes = (t ~/ 60).toString().padLeft(2, '0');
        final seconds = (t % 60).toStringAsFixed(0).padLeft(2, '0');
        textPainter.text = TextSpan(
          text: '$minutes:$seconds',
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
      oldDelegate.borderColor != borderColor ||
      oldDelegate.textDimColor != textDimColor;
}

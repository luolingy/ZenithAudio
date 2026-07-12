import 'package:flutter/material.dart';
import '../../core/utils/theme_colors.dart';
import '../../models/note.dart';
import '../../models/track.dart';

/// Compact piano-roll view rendered in-place for an instrument track.
///
/// Shows a 1-octave range (C4..B4) as rows. Tap a cell to toggle a note.
/// The [onNotesChanged] callback fires whenever notes are added/removed.
class PianoRollTrack extends StatelessWidget {
  final Track track;
  final double pixelsPerSecond;
  final ValueChanged<List<Note>>? onNotesChanged;

  const PianoRollTrack({
    super.key,
    required this.track,
    this.pixelsPerSecond = 50,
    this.onNotesChanged,
  });

  static const int _baseNote = 48; // C3
  static const int _noteCount = 24; // C3..B4

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceContainerLow;
    final gridColor = cs.outlineVariant.withAlpha(77);
    final accentColor = track.color;
    final dividerColor = Theme.of(context).dividerColor;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: dividerColor.withAlpha(77)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rowHeight = constraints.maxHeight / _noteCount;
          return GestureDetector(
            onTapUp: (details) {
              final rowIndex = (details.localPosition.dy / rowHeight).floor();
              final colSec = (details.localPosition.dx / pixelsPerSecond);
              if (rowIndex < 0 || rowIndex >= _noteCount) return;

              final pitch = _baseNote + _noteCount - 1 - rowIndex;
              final existing = track.notes.where(
                (n) => n.pitch == pitch && (n.startTime - colSec).abs() < 0.5,
              );

              List<Note> updated;
              if (existing.isNotEmpty) {
                updated = List.of(track.notes)
                  ..removeWhere((n) => n.pitch == pitch &&
                      (n.startTime - colSec).abs() < 0.5);
              } else {
                final newNote = Note(
                  pitch: pitch,
                  startTime: colSec.clamp(0, double.infinity),
                  duration: 0.5,
                  velocity: 100,
                );
                updated = List.of(track.notes)..add(newNote);
              }
              updated.sort((a, b) => a.startTime.compareTo(b.startTime));
              onNotesChanged?.call(updated);
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _PianoRollPainter(
                notes: track.notes,
                pixelsPerSecond: pixelsPerSecond,
                rowHeight: rowHeight,
                baseNote: _baseNote,
                noteCount: _noteCount,
                gridColor: gridColor,
                accentColor: accentColor,
                emptyColor: context.outline,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PianoRollPainter extends CustomPainter {
  final List<Note> notes;
  final double pixelsPerSecond;
  final double rowHeight;
  final int baseNote;
  final int noteCount;
  final Color gridColor;
  final Color accentColor;
  final Color emptyColor;

  _PianoRollPainter({
    required this.notes,
    required this.pixelsPerSecond,
    required this.rowHeight,
    required this.baseNote,
    required this.noteCount,
    required this.gridColor,
    required this.accentColor,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = gridColor..strokeWidth = 0.5;

    // Horizontal grid lines (per note row)
    for (int i = 0; i <= noteCount; i++) {
      final y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Note blocks
    final notePaint = Paint()..color = accentColor;
    final noteTextPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final note in notes) {
      final pitchIndex = baseNote + noteCount - 1 - note.pitch;
      if (pitchIndex < 0 || pitchIndex >= noteCount) continue;

      final x = note.startTime * pixelsPerSecond;
      final w = note.duration * pixelsPerSecond;
      final y = pitchIndex * rowHeight;
      final h = rowHeight - 1;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 0.5, w, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, notePaint..color = accentColor.withAlpha(160));

      // Note label inside block (if wide enough)
      if (w > 20) {
        const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
        final label = '${names[note.pitch % 12]}${(note.pitch / 12).floor() - 1}';
        noteTextPainter.text = TextSpan(
          text: label,
          style: TextStyle(color: accentColor, fontSize: 9),
        );
        noteTextPainter.layout();
        noteTextPainter.paint(canvas, Offset(x + 3, y + 1));
      }
    }

    // Beat markers (vertical)
    paint.color = emptyColor.withAlpha(51);
    paint.strokeWidth = 0.5;
    for (double t = 0; t < size.width / pixelsPerSecond; t += 1) {
      final x = t * pixelsPerSecond;
      if (x > size.width) break;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PianoRollPainter oldDelegate) =>
      oldDelegate.notes != notes ||
      oldDelegate.pixelsPerSecond != pixelsPerSecond ||
      oldDelegate.rowHeight != rowHeight ||
      oldDelegate.accentColor != accentColor;
}

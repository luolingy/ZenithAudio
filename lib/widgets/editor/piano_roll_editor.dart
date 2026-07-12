import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/track.dart';
import '../../models/note.dart';
import '../../models/project.dart';
import '../../providers/project_provider.dart';
import '../../providers/settings_provider.dart';

/// Full-screen piano roll editor for a single instrument track.
///
/// Range: C0 (MIDI 12) to C8 (MIDI 108). Notes are drawn as horizontal bars;
/// vertical position = pitch, length = duration. Supports drag, resize, snap.
class PianoRollEditor extends ConsumerStatefulWidget {
  final String trackId;

  const PianoRollEditor({super.key, required this.trackId});

  @override
  ConsumerState<PianoRollEditor> createState() => _PianoRollEditorState();
}

class _PianoRollEditorState extends ConsumerState<PianoRollEditor> {
  Track get _track =>
      ref.read(projectProvider).tracks.firstWhere((t) => t.id == widget.trackId);

  // Viewport / zoom
  double _pps = 80;
  double _noteRowHeight = 10;

  int? _dragNoteIndex;

  // Scrolling
  final ScrollController _hScrollCtrl = ScrollController();
  final ScrollController _vScrollCtrl = ScrollController();

  static const int _minNote = 12;  // C0
  static const int _maxNote = 108; // C8
  static const int _noteCount = _maxNote - _minNote + 1;

  @override
  void dispose() {
    _hScrollCtrl.dispose();
    _vScrollCtrl.dispose();
    super.dispose();
  }

  double _pitchToY(int pitch) =>
      (_maxNote - pitch) * _noteRowHeight;
  int _yToPitch(double y) =>
      (_maxNote - (y / _noteRowHeight).round()).clamp(_minNote, _maxNote);
  double _timeToX(double t) => t * _pps;
  double _xToTime(double x) => x / _pps;

  double _snapTime(double t) {
    final settings = ref.read(settingsProvider);
    if (!settings.snapToGrid) return t;
    final project = ref.read(projectProvider);
    final grid = settings.gridResolution * project.secondsPerBeat;
    if (grid <= 0) return t;
    return (t / grid).round() * grid;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final project = ref.watch(projectProvider);
    final settings = ref.watch(settingsProvider);
    final track = _track;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _buildAppBar(context, cs, track, settings),
      body: _buildBody(context, cs, track, project),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, ColorScheme cs, Track track, SettingsState settings) {
    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Icon(Icons.piano_outlined, size: 18, color: track.color),
          const SizedBox(width: 8),
          Text(track.name, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 16),
          // Snap toggle
          _ToolChip(
            icon: settings.snapToGrid ? Icons.grid_on : Icons.grid_off,
            label: settings.snapToGrid ? 'Snap ON' : 'Snap OFF',
            onTap: () => ref.read(settingsProvider.notifier).setSnapToGrid(!settings.snapToGrid),
          ),
          const SizedBox(width: 8),
          // Grid resolution
          if (settings.snapToGrid)
            _ToolChip(
              icon: Icons.tune,
              label: '1/${(1 / settings.gridResolution).round()}',
              onTap: _cycleGridResolution,
            ),
          const SizedBox(width: 16),
          // Zoom controls
          _ToolChip(
            icon: Icons.zoom_in,
            label: '',
            onTap: () => setState(() {
              _pps = (_pps * 1.3).clamp(20, 500);
              _noteRowHeight = (_noteRowHeight * 1.15).clamp(4, 40);
            }),
          ),
          const SizedBox(width: 4),
          _ToolChip(
            icon: Icons.zoom_out,
            label: '',
            onTap: () => setState(() {
              _pps = (_pps / 1.3).clamp(20, 500);
              _noteRowHeight = (_noteRowHeight / 1.15).clamp(4, 40);
            }),
          ),
        ],
      ),
    );
  }

  void _cycleGridResolution() {
    final cur = ref.read(settingsProvider).gridResolution;
    final next = cur >= 1 ? 0.5 : cur >= 0.5 ? 0.25 : cur >= 0.25 ? 0.125 : 1.0;
    ref.read(settingsProvider.notifier).setGridResolution(next);
  }

  Widget _buildBody(BuildContext context, ColorScheme cs, Track track, Project project) {
    return Row(
      children: [
        // Keyboard column
        SizedBox(
          width: 48,
          child: _buildKeyboard(context, cs),
        ),
        Container(width: 1, color: Theme.of(context).dividerColor.withAlpha(77)),
        // Grid + notes
        Expanded(child: _buildGridArea(context, cs, track, project)),
      ],
    );
  }

  Widget _buildKeyboard(BuildContext context, ColorScheme cs) {
    final divColor = Theme.of(context).dividerColor;
    return ListView.builder(
      controller: _vScrollCtrl,
      itemCount: _noteCount,
      itemExtent: _noteRowHeight,
      itemBuilder: (context, index) {
        final pitch = _maxNote - index;
        final isC = pitch % 12 == 0;
        final isBlack = [1, 3, 6, 8, 10].contains(pitch % 12);
        return Container(
          height: _noteRowHeight,
          decoration: BoxDecoration(
            color: isBlack ? Colors.black26 : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: divColor.withAlpha(38), width: 0.5),
            ),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 4),
          child: isC
              ? Text('C${(pitch ~/ 12) - 1}',
                  style: TextStyle(fontSize: 8, color: cs.onSurfaceVariant))
              : null,
        );
      },
    );
  }

  Widget _buildGridArea(
      BuildContext context, ColorScheme cs, Track track, Project project) {
    final beatSec = project.secondsPerBeat;
    final totalTime = max(project.duration, 30.0);
    final totalWidth = totalTime * _pps;

    return Scrollbar(
      controller: _hScrollCtrl,
      child: SingleChildScrollView(
        controller: _hScrollCtrl,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                // Sync keyboard scroll if needed
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _vScrollCtrl,
              child: GestureDetector(
                onDoubleTapDown: (details) {
                  _addNoteAt(details.localPosition, track, project);
                },
                onLongPressStart: (details) {
                  final idx = _noteIndexAt(details.localPosition, track);
                  if (idx != null) {
                    _showDeleteMenu(context, idx);
                  }
                },
                child: CustomPaint(
                  size: Size(totalWidth, _noteCount * _noteRowHeight),
                  painter: _PianoRollEditorPainter(
                    notes: track.notes,
                    pps: _pps,
                    noteRowHeight: _noteRowHeight,
                    minNote: _minNote,
                    maxNote: _maxNote,
                    beatSec: beatSec,
                    timeSigNum: project.timeSignatureNumerator,
                    gridColor: cs.outlineVariant.withAlpha(77),
                    beatColor: cs.outlineVariant.withAlpha(128),
                    barColor: cs.primary.withAlpha(51),
                    noteColor: track.color,
                    selectedIndex: _dragNoteIndex,
                    accentColor: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addNoteAt(Offset localPos, Track track, Project project) {
    final pitch = _yToPitch(localPos.dy);
    final t = _snapTime(_xToTime(localPos.dx));
    if (t.isNaN || t.isInfinite) return;
    final newNote = Note(pitch: pitch, startTime: t, duration: 0.5, velocity: 100);
    final updated = List<Note>.from(track.notes)
      ..add(newNote)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    ref.read(projectProvider.notifier).updateTrackNotes(widget.trackId, updated);
  }

  int? _noteIndexAt(Offset localPos, Track track) {
    for (int i = track.notes.length - 1; i >= 0; i--) {
      final n = track.notes[i];
      final y = _pitchToY(n.pitch);
      final x = _timeToX(n.startTime);
      final w = _timeToX(n.duration);
      final h = _noteRowHeight;
      if (localPos.dx >= x && localPos.dx <= x + w &&
          localPos.dy >= y && localPos.dy <= y + h) {
        return i;
      }
    }
    return null;
  }

  void _showDeleteMenu(BuildContext context, int noteIndex) {
    final track = _track;
    final note = track.notes[noteIndex];
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 200, 200),
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete note (${note.pitch})'),
        ),
      ],
    ).then((value) {
      if (value == 'delete') {
        final updated = List<Note>.from(track.notes)..removeAt(noteIndex);
        ref.read(projectProvider.notifier).updateTrackNotes(widget.trackId, updated);
      }
    });
  }
}

// ─────────────────── Tool Chip ───────────────────

class _ToolChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.outlineVariant.withAlpha(128)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.onSurfaceVariant),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────── Painter ───────────────────

class _PianoRollEditorPainter extends CustomPainter {
  final List<Note> notes;
  final double pps;
  final double noteRowHeight;
  final int minNote;
  final int maxNote;
  final double beatSec;
  final int timeSigNum;
  final Color gridColor;
  final Color beatColor;
  final Color barColor;
  final Color noteColor;
  final int? selectedIndex;
  final Color accentColor;

  _PianoRollEditorPainter({
    required this.notes,
    required this.pps,
    required this.noteRowHeight,
    required this.minNote,
    required this.maxNote,
    required this.beatSec,
    required this.timeSigNum,
    required this.gridColor,
    required this.beatColor,
    required this.barColor,
    required this.noteColor,
    this.selectedIndex,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 0.5;

    // Background fill for C notes (white key indicator)
    for (int p = minNote; p <= maxNote; p++) {
      if (p % 12 == 0) {
        final y = _pitchToY(p);
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, noteRowHeight),
          Paint()..color = Colors.white.withAlpha(8),
        );
      }
    }

    // Beat markers (vertical lines)
    final barSec = beatSec * timeSigNum;
    for (double t = 0; t < size.width / pps; t += beatSec) {
      final x = t * pps;
      if (x > size.width) break;
      final isBar = (t / barSec).round() * barSec == t && t > 0;
      paint.color = isBar ? barColor : beatColor;
      paint.strokeWidth = isBar ? 1.5 : 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal grid lines
    paint.strokeWidth = 0.5;
    paint.color = gridColor;
    for (int i = 0; i <= (maxNote - minNote); i++) {
      if (i % 12 == 0) continue; // already have background
      final y = i * noteRowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Note blocks
    for (int i = 0; i < notes.length; i++) {
      final n = notes[i];
      if (n.pitch < minNote || n.pitch > maxNote) continue;

      final x = n.startTime * pps;
      final w = n.duration * pps;
      final y = _pitchToY(n.pitch);
      final h = noteRowHeight - 1;

      final isSelected = i == selectedIndex;
      final color = isSelected ? accentColor : noteColor;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 0.5, w, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, Paint()..color = color.withAlpha(180));
      canvas.drawRRect(rrect, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = color);
    }
  }

  double _pitchToY(int pitch) => (maxNote - pitch) * noteRowHeight;

  @override
  bool shouldRepaint(covariant _PianoRollEditorPainter oldDelegate) =>
      oldDelegate.notes != notes ||
      oldDelegate.pps != pps ||
      oldDelegate.noteRowHeight != noteRowHeight ||
      oldDelegate.selectedIndex != selectedIndex;
}

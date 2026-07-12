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

  // Scrolling
  final ScrollController _hScrollCtrl = ScrollController();
  final ScrollController _vScrollCtrl = ScrollController();

  static const int _minNote = 12;  // C0
  static const int _maxNote = 108; // C8
  static const int _noteCount = _maxNote - _minNote + 1;

  // ─── Edit / Select mode ───
  bool _isSelectMode = false;
  final Set<int> _selectedIndices = {};

  // ─── Drag state ───
  int? _dragNoteIndex;
  bool _isResizing = false;
  double? _dragStartX;
  double? _dragStartY;
  List<Note>? _dragOriginNotes; // snapshot of notes at drag start

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
          // Mode toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Edit', style: TextStyle(fontSize: 11))),
              ButtonSegment(value: true, label: Text('Select', style: TextStyle(fontSize: 11))),
            ],
            selected: {_isSelectMode},
            onSelectionChanged: (v) => setState(() {
              _isSelectMode = v.first;
              if (!_isSelectMode) _selectedIndices.clear();
            }),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.piano_outlined, size: 18, color: track.color),
          const SizedBox(width: 8),
          Text(track.name, style: const TextStyle(fontSize: 14)),
          const Spacer(),
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
    return Scrollbar(
      controller: _vScrollCtrl,
      child: SingleChildScrollView(
        controller: _vScrollCtrl,
        child: SizedBox(
          height: _noteCount * _noteRowHeight,
          child: Column(
            children: List.generate(_noteCount, (i) {
              final pitch = _maxNote - i;
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
            }),
          ),
        ),
      ),
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
          child: Scrollbar(
            controller: _vScrollCtrl,
            child: SingleChildScrollView(
              controller: _vScrollCtrl,
              child: GestureDetector(
                onTapUp: (details) => _onTapUp(details, track, project),
                onPanStart: (details) => _onPanStart(details, track, project),
                onPanUpdate: (details) => _onPanUpdate(details, track, project),
                onPanEnd: (details) => _onPanEnd(details, track, project),
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
                    selectedIndices: _selectedIndices,
                    dragNoteIndex: _dragNoteIndex,
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

  // ─── Gesture handlers ───

  void _onTapUp(TapUpDetails details, Track track, Project project) {
    final localPos = details.localPosition;
    final idx = _noteIndexAt(localPos, track);

    if (_isSelectMode) {
      if (idx != null) {
        setState(() {
          if (_selectedIndices.contains(idx)) {
            _selectedIndices.remove(idx);
          } else {
            _selectedIndices.add(idx);
          }
        });
      } else {
        setState(() => _selectedIndices.clear());
      }
    } else {
      // Edit mode
      if (idx != null) {
        // Tap existing note → delete
        final updated = List<Note>.from(track.notes)..removeAt(idx);
        ref.read(projectProvider.notifier).updateTrackNotes(widget.trackId, updated);
      } else {
        // Tap empty space → add note
        _addNoteAt(localPos, track, project);
      }
    }
  }

  void _onPanStart(DragStartDetails details, Track track, Project project) {
    final localPos = details.localPosition;
    final idx = _noteIndexAt(localPos, track);
    if (idx == null) return;

    // Snapshot original notes for absolute-delta computation
    _dragOriginNotes = track.notes.map((n) => n.copyWith()).toList();

    if (_isSelectMode) {
      // Start moving selected notes
      if (!_selectedIndices.contains(idx)) {
        setState(() => _selectedIndices.add(idx));
      }
      _dragNoteIndex = idx;
      _dragStartX = localPos.dx;
      _dragStartY = localPos.dy;
      _isResizing = false;
    } else {
      // Edit mode: check if near right edge for resize
      final n = track.notes[idx];
      final noteRightX = _timeToX(n.startTime + n.duration);
      final edgeThreshold = 8.0;
      if ((localPos.dx - noteRightX).abs() < edgeThreshold) {
        _dragNoteIndex = idx;
        _dragStartX = localPos.dx;
        _isResizing = true;
      } else {
        // Move note
        _dragNoteIndex = idx;
        _dragStartX = localPos.dx;
        _dragStartY = localPos.dy;
        _isResizing = false;
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Track track, Project project) {
    if (_dragNoteIndex == null || _dragOriginNotes == null) return;
    final curX = details.localPosition.dx;
    final curY = details.localPosition.dy;

    if (_isResizing) {
      final orig = _dragOriginNotes![_dragNoteIndex!];
      final newDur = _snapTime(max(0.125, orig.duration + _xToTime(curX - (_dragStartX ?? curX))));
      final updated = List<Note>.from(track.notes);
      updated[_dragNoteIndex!] = orig.copyWith(duration: newDur);
      ref.read(projectProvider.notifier).updateTrackNotes(widget.trackId, updated);
    } else {
      // Absolute pitch / time delta from drag start → always rounded to integer pitch
      final deltaTime = _snapTime(_xToTime(curX)) - _snapTime(_xToTime(_dragStartX ?? curX));
      final deltaPitch = _yToPitch(curY) - _yToPitch(_dragStartY ?? curY);

      if (deltaTime == 0 && deltaPitch == 0) return;

      final indices = _isSelectMode ? _selectedIndices.toList() : [_dragNoteIndex!];
      final notes = List<Note>.from(track.notes);
      for (final i in indices) {
        if (i < 0 || i >= notes.length) continue;
        if (i >= _dragOriginNotes!.length) continue;
        final orig = _dragOriginNotes![i];
        notes[i] = orig.copyWith(
          startTime: max(0.0, _snapTime(orig.startTime + deltaTime)),
          pitch: (orig.pitch + deltaPitch).clamp(_minNote, _maxNote),
        );
      }
      ref.read(projectProvider.notifier).updateTrackNotes(widget.trackId, notes);
    }
  }

  void _onPanEnd(DragEndDetails details, Track track, Project project) {
    setState(() {
      _dragNoteIndex = null;
      _isResizing = false;
      _dragStartX = null;
      _dragStartY = null;
      _dragOriginNotes = null;
    });
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
  final Set<int> selectedIndices;
  final int? dragNoteIndex;
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
    this.selectedIndices = const {},
    this.dragNoteIndex,
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
      if (i % 12 == 0) continue;
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

      final isSelected = selectedIndices.contains(i) || i == dragNoteIndex;
      final color = isSelected ? accentColor : noteColor;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 0.5, w, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, Paint()..color = color.withAlpha(180));
      canvas.drawRRect(rrect, Paint()..style = PaintingStyle.stroke..strokeWidth = isSelected ? 2 : 1..color = color);
    }
  }

  double _pitchToY(int pitch) => (maxNote - pitch) * noteRowHeight;

  @override
  bool shouldRepaint(covariant _PianoRollEditorPainter oldDelegate) =>
      oldDelegate.notes != notes ||
      oldDelegate.pps != pps ||
      oldDelegate.noteRowHeight != noteRowHeight ||
      oldDelegate.selectedIndices != selectedIndices ||
      oldDelegate.dragNoteIndex != dragNoteIndex;
}

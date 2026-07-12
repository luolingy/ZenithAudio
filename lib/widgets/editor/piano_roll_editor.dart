import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/track.dart';
import '../../models/note.dart';
import '../../models/project.dart';
import '../../providers/project_provider.dart';
import '../../providers/settings_provider.dart';

/// Full-screen piano roll editor for a single instrument track.
class PianoRollEditor extends ConsumerStatefulWidget {
  final String trackId;

  const PianoRollEditor({super.key, required this.trackId});

  @override
  ConsumerState<PianoRollEditor> createState() => _PianoRollEditorState();
}

class _PianoRollEditorState extends ConsumerState<PianoRollEditor> {
  Track get _track =>
      ref.read(projectProvider).tracks.firstWhere((t) => t.id == widget.trackId);

  static const double _basePps = 40;
  static const double _baseRowH = 5;

  double _zoomLevel = 2.0;
  double get _pps => (_basePps * _zoomLevel).clamp(20, 600);
  double get _noteRowHeight => (_baseRowH * _zoomLevel).clamp(4, 60);

  // Scrolling — separate controllers for keyboard & grid to avoid "attached to multiple positions"
  final ScrollController _hScrollCtrl = ScrollController();
  final ScrollController _keyVScrollCtrl = ScrollController();
  final ScrollController _gridVScrollCtrl = ScrollController();
  bool _isSyncing = false;

  static const int _minNote = 12;
  static const int _maxNote = 108;
  static const int _noteCount = _maxNote - _minNote + 1;

  bool _isSelectMode = false;
  final Set<int> _selectedIndices = {};

  int? _dragNoteIndex;
  bool _isResizing = false;
  double? _dragStartX;
  double? _dragStartY;
  List<Note>? _dragOriginNotes;

  // ── Viewport pan state ──
  bool _isPanning = false;
  int _activePointers = 0;
  double? _panStartX;
  double? _panStartY;
  double? _panOffX;
  double? _panOffY;

  @override
  void initState() {
    super.initState();
    _keyVScrollCtrl.addListener(_syncKeyToGrid);
    _gridVScrollCtrl.addListener(_syncGridToKey);
  }

  void _syncKeyToGrid() {
    if (_isSyncing) return;
    _isSyncing = true;
    if (_gridVScrollCtrl.hasClients) {
      _gridVScrollCtrl.jumpTo(_keyVScrollCtrl.offset);
    }
    _isSyncing = false;
  }

  void _syncGridToKey() {
    if (_isSyncing) return;
    _isSyncing = true;
    if (_keyVScrollCtrl.hasClients) {
      _keyVScrollCtrl.jumpTo(_gridVScrollCtrl.offset);
    }
    _isSyncing = false;
  }

  @override
  void dispose() {
    _keyVScrollCtrl.removeListener(_syncKeyToGrid);
    _gridVScrollCtrl.removeListener(_syncGridToKey);
    _hScrollCtrl.dispose();
    _keyVScrollCtrl.dispose();
    _gridVScrollCtrl.dispose();
    super.dispose();
  }

  double _pitchToY(int pitch) => (_maxNote - pitch) * _noteRowHeight;

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
          const SizedBox(width: 8),
          Icon(Icons.piano_outlined, size: 18, color: track.color),
          const SizedBox(width: 6),
          Text(track.name, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          _ToolChip(
            icon: settings.snapToGrid ? Icons.grid_on : Icons.grid_off,
            label: settings.snapToGrid ? 'Snap ON' : 'Snap OFF',
            onTap: () => ref.read(settingsProvider.notifier).setSnapToGrid(!settings.snapToGrid),
          ),
          const SizedBox(width: 4),
          if (settings.snapToGrid)
            _ToolChip(
              icon: Icons.tune,
              label: '1/${(1 / settings.gridResolution).round()}',
              onTap: _cycleGridResolution,
            ),
          const SizedBox(width: 8),
          // Zoom slider
          SizedBox(
            width: 80,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: cs.primary,
                inactiveTrackColor: cs.outlineVariant,
                thumbColor: cs.primary,
              ),
              child: Slider(
                value: _zoomLevel,
                min: 0.5,
                max: 10.0,
                onChanged: (v) => setState(() => _zoomLevel = v),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text('${(_zoomLevel * 100).round()}%',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
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
        SizedBox(
          width: 48,
          child: _buildKeyboard(context, cs),
        ),
        Container(width: 1, color: Theme.of(context).dividerColor.withAlpha(77)),
        Expanded(child: _buildGridArea(context, cs, track, project)),
      ],
    );
  }

  Widget _buildKeyboard(BuildContext context, ColorScheme cs) {
    final divColor = Theme.of(context).dividerColor;
    return SingleChildScrollView(
      controller: _keyVScrollCtrl,
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
            controller: _gridVScrollCtrl,
            child: SingleChildScrollView(
              controller: _gridVScrollCtrl,
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                behavior: HitTestBehavior.translucent,
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
      ),
    );
  }

  // ── Viewport pan (middle-mouse / two-finger touch) ──

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    if ((event.buttons & 4) != 0) {
      // Secondary button → initiate pan
      _startPan(event.localPosition);
    } else if (_activePointers >= 2) {
      // Two-finger touch → cancel note drag & start pan
      if (_dragNoteIndex != null) {
        setState(() {
          _dragNoteIndex = null;
          _isResizing = false;
          _dragStartX = null;
          _dragStartY = null;
          _dragOriginNotes = null;
        });
      }
      _startPan(event.localPosition);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isPanning && _panStartX != null && _panStartY != null) {
      final dx = event.localPosition.dx - _panStartX!;
      final dy = event.localPosition.dy - _panStartY!;

      if (_hScrollCtrl.hasClients) {
        _hScrollCtrl.jumpTo((_panOffX! - dx).clamp(0, _hScrollCtrl.position.maxScrollExtent));
      }
      if (_gridVScrollCtrl.hasClients) {
        _gridVScrollCtrl.jumpTo((_panOffY! - dy).clamp(0, _gridVScrollCtrl.position.maxScrollExtent));
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers = max(0, _activePointers - 1);
    if (_activePointers < 2) {
      _isPanning = false;
    }
  }

  void _startPan(Offset localPos) {
    _isPanning = true;
    _panStartX = localPos.dx;
    _panStartY = localPos.dy;
    _panOffX = _hScrollCtrl.hasClients ? _hScrollCtrl.offset : 0;
    _panOffY = _gridVScrollCtrl.hasClients ? _gridVScrollCtrl.offset : 0;
  }

  // ── Gesture handlers (note operations) ──

  void _onTapUp(TapUpDetails details, Track track, Project project) {
    if (_isPanning) return;
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
      if (idx != null) {
        final updated = List<Note>.from(track.notes)..removeAt(idx);
        ref.read(projectProvider.notifier).updateTrackNotes(widget.trackId, updated);
      } else {
        _addNoteAt(localPos, track, project);
      }
    }
  }

  void _onPanStart(DragStartDetails details, Track track, Project project) {
    if (_isPanning) return;
    final localPos = details.localPosition;
    final idx = _noteIndexAt(localPos, track);
    if (idx == null) return;

    _dragOriginNotes = track.notes.map((n) => n.copyWith()).toList();

    if (_isSelectMode) {
      if (!_selectedIndices.contains(idx)) {
        setState(() => _selectedIndices.add(idx));
      }
      _dragNoteIndex = idx;
      _dragStartX = localPos.dx;
      _dragStartY = localPos.dy;
      _isResizing = false;
    } else {
      final n = track.notes[idx];
      final noteRightX = _timeToX(n.startTime + n.duration);
      final edgeThreshold = 8.0;
      if ((localPos.dx - noteRightX).abs() < edgeThreshold) {
        _dragNoteIndex = idx;
        _dragStartX = localPos.dx;
        _isResizing = true;
      } else {
        _dragNoteIndex = idx;
        _dragStartX = localPos.dx;
        _dragStartY = localPos.dy;
        _isResizing = false;
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Track track, Project project) {
    if (_isPanning || _dragNoteIndex == null || _dragOriginNotes == null) return;
    final curX = details.localPosition.dx;
    final curY = details.localPosition.dy;

    if (_isResizing) {
      final orig = _dragOriginNotes![_dragNoteIndex!];
      final rawDelta = (_xToTime(curX) - _xToTime(_dragStartX!));
      final newDur = max(0.125, _snapTime(orig.duration + rawDelta));
      final updated = List<Note>.from(track.notes);
      updated[_dragNoteIndex!] = orig.copyWith(duration: newDur);
      ref.read(projectProvider.notifier).updateTrackNotes(widget.trackId, updated);
    } else {
      // Raw (un-snapped) delta → snap only the final result → smooth movement
      final rawDeltaTime = _xToTime(curX) - _xToTime(_dragStartX!);
      final rawDeltaPitch = (curY - _dragStartY!) / _noteRowHeight;
      final deltaPitch = rawDeltaPitch.round();

      if (rawDeltaTime == 0 && deltaPitch == 0) return;

      final indices = _isSelectMode ? _selectedIndices.toList() : [_dragNoteIndex!];
      final notes = List<Note>.from(track.notes);
      for (final i in indices) {
        if (i < 0 || i >= notes.length) continue;
        if (i >= _dragOriginNotes!.length) continue;
        final orig = _dragOriginNotes![i];
        notes[i] = orig.copyWith(
          startTime: max(0.0, _snapTime(orig.startTime + rawDeltaTime)),
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

    for (int p = minNote; p <= maxNote; p++) {
      if (p % 12 == 0) {
        final y = _pitchToY(p);
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, noteRowHeight),
          Paint()..color = Colors.white.withAlpha(8),
        );
      }
    }

    final barSec = beatSec * timeSigNum;
    for (double t = 0; t < size.width / pps; t += beatSec) {
      final x = t * pps;
      if (x > size.width) break;
      final isBar = (t / barSec).round() * barSec == t && t > 0;
      paint.color = isBar ? barColor : beatColor;
      paint.strokeWidth = isBar ? 1.5 : 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    paint.strokeWidth = 0.5;
    paint.color = gridColor;
    for (int i = 0; i <= (maxNote - minNote); i++) {
      if (i % 12 == 0) continue;
      final y = i * noteRowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

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

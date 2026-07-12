import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:path_provider/path_provider.dart';
import '../../models/track.dart';
import '../../models/note.dart';
import '../../models/project.dart';
import '../../models/instrument.dart';
import '../../providers/project_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/synth_service.dart';

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

  final ScrollController _hScrollCtrl = ScrollController();
  final ScrollController _keyVScrollCtrl = ScrollController();
  final ScrollController _gridVScrollCtrl = ScrollController();
  bool _isSyncing = false;

  static const int _minNote = 12;
  static const int _maxNote = 108;
  static const int _noteCount = _maxNote - _minNote + 1;

  bool _isSelectMode = false;
  final Set<int> _selectedIndices = {};

  // Drag state
  int? _dragNoteIndex;
  bool _isResizing = false;
  double? _dragStartX;
  double? _dragStartY;
  List<Note>? _dragOriginNotes;
  List<Note>? _localDragNotes;
  List<Rect> _ghostRects = [];

  // Viewport pan
  bool _isPanning = false;
  int _activePointers = 0;
  double? _panStartX;
  double? _panStartY;
  double? _panOffX;
  double? _panOffY;

  // Pinch-to-zoom
  final Map<int, Offset> _pointerPos = {};
  double? _pinchStartDist;
  double? _pinchStartZoom;

  bool _isCtrlDown = false;

  // Playback
  Player? _previewPlayer;
  bool _isPlaying = false;
  double _playPos = 0;
  final _synth = SynthService();
  StreamSubscription? _posSub;
  StreamSubscription? _completedSub;

  @override
  void initState() {
    super.initState();
    _keyVScrollCtrl.addListener(_syncKeyToGrid);
    _gridVScrollCtrl.addListener(_syncGridToKey);
  }

  @override
  void dispose() {
    _stopPlayback();
    _keyVScrollCtrl.removeListener(_syncKeyToGrid);
    _gridVScrollCtrl.removeListener(_syncGridToKey);
    _hScrollCtrl.dispose();
    _keyVScrollCtrl.dispose();
    _gridVScrollCtrl.dispose();
    super.dispose();
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
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: _buildBody(context, cs, track, project),
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight) {
      _isCtrlDown = event is KeyDownEvent;
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space &&
        event is KeyDownEvent) {
      _togglePlayback();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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
          // Transport controls
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 20, color: cs.primary,
            ),
            onPressed: _togglePlayback,
            tooltip: _isPlaying ? 'Pause' : 'Play',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.stop, size: 18, color: cs.onSurfaceVariant),
            onPressed: _stopPlayback,
            tooltip: 'Stop',
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
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

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      _previewPlayer?.pause();
      setState(() => _isPlaying = false);
    } else {
      await _startPlayback();
    }
  }

  Future<void> _startPlayback() async {
    final track = _track;
    if (track.notes.isEmpty || track.instrumentName == null) return;

    final inst = InstrumentPreset.fromId(track.instrumentName!);
    final dur = track.computedDuration > 0 ? track.computedDuration + 0.5 : 2.0;
    final numSamples = (44100 * dur).ceil();

    final buffer = Float64List(numSamples);
    final sampleRate = 44100;
    for (final note in track.notes) {
      final startSample = (note.startTime * sampleRate).round();
      final durSamples = (note.duration * sampleRate).round();
      final endSample = (startSample + durSamples).clamp(0, numSamples);
      final freq = 440 * pow(2, (note.pitch - 69) / 12).toDouble();
      for (int i = startSample; i < endSample; i++) {
        final t = (i - startSample) / sampleRate;
        final env = inst.getEnvelope(t, note.duration, note.velocity);
        buffer[i] += inst.synthSample(t, freq, note.velocity) * env;
      }
    }

    double maxAmp = 0;
    for (final s in buffer) {
      final a = s.abs();
      if (a > maxAmp) maxAmp = a;
    }
    if (maxAmp > 0 && maxAmp > 0.95) {
      final scale = 0.95 / maxAmp;
      for (int i = 0; i < buffer.length; i++) {
        buffer[i] *= scale;
      }
    }

    final wav = _encodeWav(buffer, numSamples, sampleRate);
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/editor_preview.wav';
    await File(filePath).writeAsBytes(wav);

    final player = Player();
    _previewPlayer = player;
    setState(() => _isPlaying = true);

    _posSub = player.stream.position.listen((pos) {
      if (mounted) setState(() => _playPos = pos.inMilliseconds / 1000.0);
    });
    _completedSub = player.stream.completed.listen((_) {
      if (mounted) _onPlayEnd();
    });
    player.stream.error.listen((_) {
      if (mounted) _onPlayEnd();
    });

    try {
      final uri = Uri.file(filePath).toString();
      await player.open(Media(uri));
      await player.setVolume(100);
      player.play();
    } catch (_) {
      _onPlayEnd();
    }
  }

  void _onPlayEnd() {
    _stopPlayback();
  }

  void _stopPlayback() {
    _posSub?.cancel(); _posSub = null;
    _completedSub?.cancel(); _completedSub = null;
    _previewPlayer?.stop();
    _previewPlayer?.dispose();
    _previewPlayer = null;
    if (mounted) setState(() { _isPlaying = false; _playPos = 0; });
  }

  Uint8List _encodeWav(Float64List buffer, int numSamples, int sampleRate) {
    final bytesPerSample = 2;
    final dataSize = numSamples * bytesPerSample;
    final fileSize = 44 + dataSize;
    final result = DataWriter(fileSize);
    result.writeString('RIFF');
    result.writeInt32(fileSize - 8);
    result.writeString('WAVE');
    result.writeString('fmt ');
    result.writeInt32(16);
    result.writeInt16(1);
    result.writeInt16(1);
    result.writeInt32(sampleRate);
    result.writeInt32(sampleRate * bytesPerSample);
    result.writeInt16(bytesPerSample);
    result.writeInt16(16);
    result.writeString('data');
    result.writeInt32(dataSize);
    for (int i = 0; i < numSamples; i++) {
      final clamped = buffer[i].clamp(-1.0, 1.0);
      final sample = (clamped * 32767).round().clamp(-32768, 32767);
      result.writeInt16(sample);
    }
    return result.bytes;
  }

  Future<void> _previewNote(int pitch) async {
    final track = _track;
    if (track.instrumentName == null) return;
    final inst = InstrumentPreset.fromId(track.instrumentName!);
    final wav = _synth.renderPreviewWav(inst, pitch: pitch, duration: 0.3, velocity: 100);

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/note_preview.wav';
    await File(filePath).writeAsBytes(wav);

    _previewPlayer?.stop();
    _previewPlayer?.dispose();
    final player = Player();
    _previewPlayer = player;
    player.stream.completed.listen((_) {
      if (_previewPlayer == player) { _previewPlayer = null; }
      player.dispose();
    });

    try {
      await player.open(Media(Uri.file(filePath).toString()));
      await player.setVolume(80);
      player.play();
    } catch (_) {
      player.dispose();
      if (_previewPlayer == player) _previewPlayer = null;
    }
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
          child: _buildKeyboard(context, cs, track),
        ),
        Container(width: 1, color: Theme.of(context).dividerColor.withAlpha(77)),
        Expanded(child: _buildGridArea(context, cs, track, project)),
      ],
    );
  }

  Widget _buildKeyboard(BuildContext context, ColorScheme cs, Track track) {
    final divColor = Theme.of(context).dividerColor;
    final hasInstrument = track.instrumentName != null;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        controller: _keyVScrollCtrl,
        child: SizedBox(
          height: _noteCount * _noteRowHeight,
          child: Column(
            children: List.generate(_noteCount, (i) {
              final pitch = _maxNote - i;
              final isC = pitch % 12 == 0;
              final isBlack = [1, 3, 6, 8, 10].contains(pitch % 12);
              return GestureDetector(
                onTap: hasInstrument ? () => _previewNote(pitch) : null,
                child: Container(
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
                ),
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
    final notes = _localDragNotes ?? track.notes;

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
                onPointerSignal: _onPointerSignal,
                behavior: HitTestBehavior.translucent,
                child: GestureDetector(
                  onTapUp: (details) => _onTapUp(details, track, project),
                  onPanStart: (details) => _onPanStart(details, track),
                  onPanUpdate: (details) => _onPanUpdate(details),
                  onPanEnd: (details) => _onPanEnd(track),
                  child: CustomPaint(
                    size: Size(totalWidth, _noteCount * _noteRowHeight),
                    painter: _PianoRollEditorPainter(
                      notes: notes,
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
                      ghostRects: _ghostRects,
                      playPos: _isPlaying ? _playPos : null,
                      playheadColor: cs.primary,
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

  // ── Viewport pan / pinch zoom / scroll-wheel zoom ──

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    _pointerPos[event.pointer] = event.localPosition;

    if ((event.buttons & 4) != 0) {
      _startPan(event.localPosition);
    } else if (_activePointers == 2) {
      _dragNoteIndex = null;
      _isResizing = false;
      _dragStartX = null;
      _dragStartY = null;
      _dragOriginNotes = null;
      _localDragNotes = null;
      _ghostRects = [];
      _startPan(event.localPosition);
      final pts = _pointerPos.values.toList();
      _pinchStartDist = (pts[1] - pts[0]).distance;
      _pinchStartZoom = _zoomLevel;
    } else if (_activePointers > 2) {
      _startPan(event.localPosition);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _pointerPos[event.pointer] = event.localPosition;

    if (_isPanning && _panStartX != null && _panStartY != null) {
      if (_activePointers >= 2 && _pinchStartDist != null && _pinchStartDist! > 0 && _pinchStartZoom != null && _pointerPos.length >= 2) {
        final pts = _pointerPos.values.toList();
        final dist = (pts[0] - pts[1]).distance;
        final newZoom = (_pinchStartZoom! * (dist / _pinchStartDist!)).clamp(0.5, 10.0);
        setState(() => _zoomLevel = newZoom);
      }
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
    _pointerPos.remove(event.pointer);
    if (_activePointers < 2) {
      _isPanning = false;
      _pinchStartDist = null;
      _pinchStartZoom = null;
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _isCtrlDown) {
      setState(() {
        _zoomLevel = (_zoomLevel * (event.scrollDelta.dy < 0 ? 1.15 : 0.85)).clamp(0.5, 10.0);
      });
    }
  }

  void _startPan(Offset localPos) {
    _isPanning = true;
    _panStartX = localPos.dx;
    _panStartY = localPos.dy;
    _panOffX = _hScrollCtrl.hasClients ? _hScrollCtrl.offset : 0;
    _panOffY = _gridVScrollCtrl.hasClients ? _gridVScrollCtrl.offset : 0;
  }

  // ── Tap / Drag ──

  void _onTapUp(TapUpDetails details, Track track, Project project) {
    if (_isPanning) return;
    final localPos = details.localPosition;
    final idx = _noteIndexAt(localPos, track.notes);

    if (_isSelectMode) {
      if (idx >= 0) {
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
      if (idx >= 0) {
        final updated = List<Note>.from(track.notes)..removeAt(idx);
        ref.read(projectProvider.notifier).updateTrackNotes(widget.trackId, updated);
      } else {
        _addNoteAt(localPos, track, project);
      }
    }
  }

  void _onPanStart(DragStartDetails details, Track track) {
    if (_isPanning) return;
    final localPos = details.localPosition;
    final idx = _noteIndexAt(localPos, track.notes);
    if (idx < 0) return;

    _dragOriginNotes = track.notes.map((n) => n.copyWith()).toList();
    _localDragNotes = List<Note>.from(track.notes);
    _ghostRects = [];

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
      if ((localPos.dx - noteRightX).abs() < 8.0) {
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

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isPanning || _dragNoteIndex == null || _dragOriginNotes == null || _localDragNotes == null) return;
    final curX = details.localPosition.dx;
    final curY = details.localPosition.dy;

    _ghostRects = [];

    if (_isResizing) {
      final orig = _dragOriginNotes![_dragNoteIndex!];
      final rawDelta = _xToTime(curX) - _xToTime(_dragStartX!);
      final newDur = max(0.125, _snapTime(orig.duration + rawDelta));
      _localDragNotes![_dragNoteIndex!] = orig.copyWith(duration: newDur);
      // Ghost for resize
      final ghostX = orig.startTime * _pps;
      final ghostW = newDur * _pps;
      _ghostRects.add(Rect.fromLTWH(ghostX, _pitchToY(orig.pitch), ghostW, _noteRowHeight - 1));
    } else {
      final rawDeltaTime = _xToTime(curX) - _xToTime(_dragStartX!);
      final rawDeltaPitch = (_dragStartY! - curY) / _noteRowHeight;
      final deltaPitch = rawDeltaPitch.round();
      if (rawDeltaTime == 0 && deltaPitch == 0) return;

      final indices = _isSelectMode ? _selectedIndices.toList() : [_dragNoteIndex!];
      for (final i in indices) {
        if (i < 0 || i >= _localDragNotes!.length) continue;
        if (i >= _dragOriginNotes!.length) continue;
        final orig = _dragOriginNotes![i];
        final snapTime = max(0.0, _snapTime(orig.startTime + rawDeltaTime));
        final snapPitch = (orig.pitch + deltaPitch).clamp(_minNote, _maxNote);
        _localDragNotes![i] = orig.copyWith(startTime: snapTime, pitch: snapPitch);
        _ghostRects.add(Rect.fromLTWH(
          snapTime * _pps, _pitchToY(snapPitch),
          orig.duration * _pps, _noteRowHeight - 1,
        ));
      }
    }
    setState(() {});
  }

  void _onPanEnd(Track track) {
    if (_localDragNotes != null) {
      ref.read(projectProvider.notifier).updateTrackNotes(widget.trackId, _localDragNotes!);
    }
    setState(() {
      _dragNoteIndex = null;
      _isResizing = false;
      _dragStartX = null;
      _dragStartY = null;
      _dragOriginNotes = null;
      _localDragNotes = null;
      _ghostRects = [];
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

  int _noteIndexAt(Offset localPos, List<Note> notes) {
    for (int i = notes.length - 1; i >= 0; i--) {
      final n = notes[i];
      final y = _pitchToY(n.pitch);
      final x = _timeToX(n.startTime);
      final w = _timeToX(n.duration);
      final h = _noteRowHeight;
      if (localPos.dx >= x && localPos.dx <= x + w &&
          localPos.dy >= y && localPos.dy <= y + h) {
        return i;
      }
    }
    return -1;
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
  final List<Rect> ghostRects;
  final double? playPos;
  final Color playheadColor;

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
    this.ghostRects = const [],
    this.playPos,
    required this.playheadColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 0.5;

    // C-note background highlight
    for (int p = minNote; p <= maxNote; p++) {
      if (p % 12 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(0, _pitchToY(p), size.width, noteRowHeight),
          Paint()..color = Colors.white.withAlpha(8),
        );
      }
    }

    // Beat / bar lines
    final barSec = beatSec * timeSigNum;
    for (double t = 0; t < size.width / pps; t += beatSec) {
      final x = t * pps;
      if (x > size.width) break;
      final isBar = (t / barSec).round() * barSec == t && t > 0;
      paint.color = isBar ? barColor : beatColor;
      paint.strokeWidth = isBar ? 1.5 : 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal grid
    paint.strokeWidth = 0.5;
    paint.color = gridColor;
    for (int i = 0; i <= (maxNote - minNote); i++) {
      if (i % 12 == 0) continue;
      canvas.drawLine(Offset(0, i * noteRowHeight), Offset(size.width, i * noteRowHeight), paint);
    }

    // Ghost snap rects (drawn BELOW notes)
    for (final r in ghostRects) {
      final ghostRRect = RRect.fromRectAndRadius(r, const Radius.circular(2));
      canvas.drawRRect(ghostRRect, Paint()..color = noteColor.withAlpha(40));
      canvas.drawRRect(ghostRRect, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = noteColor.withAlpha(80));
    }

    // Note blocks
    for (int i = 0; i < notes.length; i++) {
      final n = notes[i];
      if (n.pitch < minNote || n.pitch > maxNote) continue;

      final x = n.startTime * pps;
      final w = n.duration * pps;
      final y = _pitchToY(n.pitch);
      final h = noteRowHeight - 1;

      final isDragged = i == dragNoteIndex;
      final isSelected = selectedIndices.contains(i) || isDragged;
      final color = isSelected ? accentColor : noteColor;

      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, y + 0.5, w, h), const Radius.circular(2));

      if (isDragged) {
        // Shadow: offset rect behind the dragged note (looks "picked up")
        final shadowRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 3, y + 2.5, w, h), const Radius.circular(2));
        canvas.drawRRect(shadowRect, Paint()..color = Colors.black.withAlpha(60));
        // Brighter fill for dragged note
        canvas.drawRRect(rrect, Paint()..color = accentColor.withAlpha(220));
        canvas.drawRRect(rrect, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accentColor);
      } else {
        canvas.drawRRect(rrect, Paint()..color = color.withAlpha(180));
        canvas.drawRRect(rrect, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2 : 1
          ..color = color);
      }
    }

    // Playhead
    if (playPos != null) {
      final phx = playPos! * pps;
      paint.color = playheadColor;
      paint.strokeWidth = 2;
      canvas.drawLine(Offset(phx, 0), Offset(phx, size.height), paint);
    }
  }

  double _pitchToY(int pitch) => (maxNote - pitch) * noteRowHeight;

  @override
  bool shouldRepaint(covariant _PianoRollEditorPainter oldDelegate) =>
      oldDelegate.notes != notes ||
      oldDelegate.pps != pps ||
      oldDelegate.noteRowHeight != noteRowHeight ||
      oldDelegate.selectedIndices != selectedIndices ||
      oldDelegate.dragNoteIndex != dragNoteIndex ||
      oldDelegate.ghostRects != ghostRects ||
      oldDelegate.playPos != playPos;
}

// ─────────────────── WAV encoder (inline) ───────────────────

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

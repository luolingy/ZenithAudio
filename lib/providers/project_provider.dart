import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/track.dart';
import '../models/note.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../services/audio_service.dart';
import '../services/project_serializer.dart';

final projectProvider = NotifierProvider<ProjectNotifier, Project>(
  ProjectNotifier.new,
);

class ProjectNotifier extends Notifier<Project> {
  static const _uuid = Uuid();
  static const int _maxUndo = 50;

  /// Current save path for the project (set after first save or open).
  String? _currentFilePath;

  final List<Project> _undoStack = [];
  final List<Project> _redoStack = [];

  @override
  Project build() {
    ref.onDispose(() {
      ref.read(audioServiceProvider).dispose();
    });
    return Project(id: _uuid.v4(), name: 'untitled');
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  Project _deepClone(Project p) {
    return Project(
      id: p.id,
      name: p.name,
      tracks: p.tracks.map((t) => t.copyWith(
        notes: t.notes.map((n) => n.copyWith()).toList(),
      )).toList(),
      sampleRate: p.sampleRate,
      timeSignatureNumerator: p.timeSignatureNumerator,
      timeSignatureDenominator: p.timeSignatureDenominator,
      keySignature: p.keySignature,
      bpm: p.bpm,
      playbackSpeed: p.playbackSpeed,
    );
  }

  void _pushUndo() {
    _undoStack.add(_deepClone(state));
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_deepClone(state));
    state = _undoStack.removeLast();
    AppLogger.i('Undo');
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_deepClone(state));
    state = _redoStack.removeLast();
    AppLogger.i('Redo');
  }

  // ──── Save / Open ────

  Future<void> saveProject() async {
    try {
      AppLogger.i('Saving project...');

      // Show file picker first, before serialization
      String? outputPath;
      if (kIsWeb) {
        outputPath = 'web';
      } else {
        if (_currentFilePath != null && await File(_currentFilePath!).exists()) {
          outputPath = _currentFilePath;
        } else {
          try {
            outputPath = await FilePicker.platform.saveFile(
              dialogTitle: 'Save Project',
              fileName: '${state.name}${AppConstants.projectExtension}',
              type: FileType.custom,
              allowedExtensions: ['zap'],
            );
          } catch (e) {
            AppLogger.e('File picker error', e);
            return;
          }
        }
      }

      if (outputPath == null) return; // User cancelled

      // Serialize project data
      final audioBytes = <String, Uint8List>{};
      final serializer = ProjectSerializer();
      final bytes = await serializer.serialize(state, audioFileBytes: audioBytes);

      if (kIsWeb) {
        final webSerializer = ProjectSerializer();
        webSerializer.downloadArchive(bytes, '${state.name}${AppConstants.projectExtension}');
        AppLogger.i('Project saved via browser download');
      } else {
        await File(outputPath).writeAsBytes(bytes);
        _currentFilePath = outputPath;
        AppLogger.i('Project saved to: $outputPath');
      }
    } catch (e) {
      AppLogger.e('Failed to save project', e);
    }
  }

  Future<void> openProject() async {
    _pushUndo();
    try {
      AppLogger.i('Opening project...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zap'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      Uint8List bytes;
      if (kIsWeb) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
        _currentFilePath = file.path;
      } else {
        return;
      }

      final serializer = ProjectSerializer();
      final serialized = await serializer.deserialize(bytes);
      if (serialized == null) {
        AppLogger.e('Failed to deserialize project');
        return;
      }

      final audioService = ref.read(audioServiceProvider);
      await audioService.unloadAll();

      final updatedTracks = serialized.project.tracks.map((t) {
        if (t.type == TrackType.audio) {
          final audioPath = serialized.trackAudioFiles[t.id];
          return audioPath != null ? t.copyWith(audioFilePath: audioPath) : t;
        }
        return t;
      }).toList();
      state = serialized.project.copyWith(tracks: updatedTracks);

      for (final track in state.tracks) {
        if (track.type == TrackType.audio && track.audioFilePath != null) {
          audioService.loadTrack(track).then((dur) {
            final updated = track.copyWith(duration: dur);
            state = state.copyWith(
              tracks: state.tracks.map((t) => t.id == track.id ? updated : t).toList(),
            );
          });
        }
      }

      AppLogger.i('Project loaded: ${state.name}');
    } catch (e) {
      AppLogger.e('Failed to open project', e);
    }
  }

  // ──── Track management ────

  void addAudioTrack({String? name, String? audioFilePath}) {
    _pushUndo();
    final trackColors = _trackColors();
    final track = Track(
      id: _uuid.v4(),
      name: name ?? 'Track ${state.tracks.length + 1}',
      type: TrackType.audio,
      volume: 0.8,
      audioFilePath: audioFilePath,
      color: trackColors[state.tracks.length % trackColors.length],
    );

    state = state.copyWith(tracks: [...state.tracks, track]);
    if (audioFilePath != null) {
      ref.read(audioServiceProvider).loadTrack(track).then((dur) {
        final updated = track.copyWith(duration: dur);
        state = state.copyWith(
          tracks: state.tracks.map((t) => t.id == track.id ? updated : t).toList(),
        );
        AppLogger.d('Track "${track.name}" duration: ${dur.toStringAsFixed(1)}s');
      });
    }
    AppLogger.i('Added audio track: ${track.name}');
  }

  void addInstrumentTrack({String? name, String? instrumentName}) {
    _pushUndo();
    final trackColors = _trackColors();
    final track = Track(
      id: _uuid.v4(),
      name: name ?? 'Track ${state.tracks.length + 1}',
      type: TrackType.instrument,
      instrumentName: instrumentName ?? 'piano',
      volume: 0.8,
      color: trackColors[state.tracks.length % trackColors.length],
    );

    state = state.copyWith(tracks: [...state.tracks, track]);
    AppLogger.i('Added instrument track: ${track.name}');
  }

  void addTrack({String? name, String? audioFilePath}) {
    addAudioTrack(name: name, audioFilePath: audioFilePath);
  }

  Future<void> removeTrack(String trackId) async {
    _pushUndo();
    await ref.read(audioServiceProvider).unloadTrack(trackId);
    final removedName = state.tracks.firstWhere((t) => t.id == trackId).name;
    state = state.copyWith(
      tracks: state.tracks.where((t) => t.id != trackId).toList(),
    );
    AppLogger.i('Deleted track: $removedName');
  }

  void updateTrackVolume(String trackId, double volume) {
    final trackName = state.tracks.firstWhere((t) => t.id == trackId).name;
    state = state.copyWith(
      tracks: state.tracks.map((t) {
        if (t.id == trackId) return t.copyWith(volume: volume);
        return t;
      }).toList(),
    );
    ref.read(audioServiceProvider).updateTrackVolume(trackId, volume);
    AppLogger.d('Track "$trackName" volume: ${(volume * 100).toInt()}%');
  }

  void toggleTrackMute(String trackId) {
    final track = state.tracks.firstWhere((t) => t.id == trackId);
    final newMuted = !track.isMuted;
    state = state.copyWith(
      tracks: state.tracks.map((t) {
        if (t.id == trackId) return t.copyWith(isMuted: newMuted);
        return t;
      }).toList(),
    );
    _syncVolumes();
    AppLogger.i('Track "${track.name}" ${newMuted ? "muted" : "unmuted"}');
  }

  void toggleTrackSolo(String trackId) {
    final track = state.tracks.firstWhere((t) => t.id == trackId);
    final newSolo = !track.isSolo;
    state = state.copyWith(
      tracks: state.tracks.map((t) {
        if (t.id == trackId) return t.copyWith(isSolo: newSolo);
        return t;
      }).toList(),
    );
    _syncVolumes();
    AppLogger.i('Track "${track.name}" ${newSolo ? "solo" : "unsolo"}');
  }

  void _syncVolumes() {
    final audio = ref.read(audioServiceProvider);
    final hasSolo = state.hasSoloTrack;
    for (final t in state.tracks) {
      final effectiveVol = hasSolo
          ? (t.isSolo ? t.volume : 0.0)
          : (t.isMuted ? 0.0 : t.volume);
      audio.updateTrackVolume(t.id, effectiveVol);
    }
  }

  void setTrackAudioFile(String trackId, String filePath) {
    state = state.copyWith(
      tracks: state.tracks.map((t) {
        if (t.id == trackId) return t.copyWith(audioFilePath: filePath);
        return t;
      }).toList(),
    );
  }

  void renameTrack(String trackId, String newName) {
    _pushUndo();
    state = state.copyWith(
      tracks: state.tracks.map((t) {
        if (t.id == trackId) return t.copyWith(name: newName);
        return t;
      }).toList(),
    );
  }

  void updateTrackNotes(String trackId, List<Note> notes) {
    _pushUndo();
    state = state.copyWith(
      tracks: state.tracks.map((t) {
        if (t.id == trackId) return t.copyWith(notes: notes);
        return t;
      }).toList(),
    );
  }

  void setTrackInstrument(String trackId, String instrumentName) {
    _pushUndo();
    state = state.copyWith(
      tracks: state.tracks.map((t) {
        if (t.id == trackId) return t.copyWith(instrumentName: instrumentName);
        return t;
      }).toList(),
    );
  }

  void setTimeSignature(int numerator, int denominator) {
    _pushUndo();
    state = state.copyWith(
      timeSignatureNumerator: numerator,
      timeSignatureDenominator: denominator,
    );
    AppLogger.i('Time signature: $numerator/$denominator');
  }

  void setKeySignature(String key) {
    _pushUndo();
    state = state.copyWith(keySignature: key);
    AppLogger.i('Key signature: $key');
  }

  void setBpm(double bpm) {
    _pushUndo();
    state = state.copyWith(bpm: bpm.clamp(20, 300));
    AppLogger.i('BPM: ${bpm.toStringAsFixed(1)}');
  }

  void setPlaybackSpeed(double speed) {
    _pushUndo();
    state = state.copyWith(playbackSpeed: speed.clamp(0.25, 4.0));
    ref.read(audioServiceProvider).setPlaybackSpeed(speed.clamp(0.25, 4.0));
    AppLogger.i('Playback speed: ${speed.toStringAsFixed(2)}x');
  }

  Future<void> newProject() async {
    _pushUndo();
    await ref.read(audioServiceProvider).unloadAll();
    _currentFilePath = null;
    state = Project(id: _uuid.v4(), name: 'Untitled');
    AppLogger.i('New project created');
  }

  List<Color> _trackColors() => [
    const Color(0xFF40C4FF),
    const Color(0xFF69F0AE),
    const Color(0xFFFFD740),
    const Color(0xFFFF8A65),
    const Color(0xFFCE93D8),
    const Color(0xFF4DB6AC),
    const Color(0xFFF06292),
    const Color(0xFFAED581),
  ];
}

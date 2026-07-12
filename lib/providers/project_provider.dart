import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/track.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../services/audio_service.dart';
import '../services/project_serializer.dart';

final projectProvider = NotifierProvider<ProjectNotifier, Project>(
  ProjectNotifier.new,
);

class ProjectNotifier extends Notifier<Project> {
  static const _uuid = Uuid();

  /// Current save path for the project (set after first save or open).
  String? _currentFilePath;

  @override
  Project build() {
    ref.onDispose(() {
      ref.read(audioServiceProvider).unloadAll();
    });
    return Project(id: _uuid.v4(), name: 'untitled');
  }

  // ──── Save / Open ────

  /// Serialize and save the current project to a .zap file.
  ///
  /// On desktop, uses FilePicker.saveFile() to let the user choose a location.
  /// On web, triggers a browser download.
  Future<void> saveProject() async {
    try {
      AppLogger.i('Saving project...');

      // 1. Collect audio file bytes for each track.
      final audioBytes = <String, Uint8List>{};
      final audioService = ref.read(audioServiceProvider);

      // On web, fetch audio bytes from blob URLs if available.
      // On desktop, the serializer reads from disk directly.

      // 2. Serialize project to .zap bytes.
      final serializer = ProjectSerializer();
      final bytes = await serializer.serialize(state, audioFileBytes: audioBytes);

      // 3. Save to file.
      if (kIsWeb) {
        // Web: trigger browser download.
        // ignore: undefined_prefixed_name
        final webSerializer = ProjectSerializer();
        webSerializer.downloadArchive(bytes, '${state.name}${AppConstants.projectExtension}');
        AppLogger.i('Project saved via browser download');
      } else {
        // Desktop: use file picker save dialog.
        String? outputPath;
        if (_currentFilePath != null && await File(_currentFilePath!).exists()) {
          outputPath = _currentFilePath;
        } else {
          outputPath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Project',
            fileName: '${state.name}${AppConstants.projectExtension}',
            type: FileType.custom,
            allowedExtensions: ['zap'],
          );
        }

        if (outputPath != null) {
          await File(outputPath).writeAsBytes(bytes);
          _currentFilePath = outputPath;
          AppLogger.i('Project saved to: $outputPath');
        }
      }
    } catch (e) {
      AppLogger.e('Failed to save project', e);
    }
  }

  /// Open and load a .zap project file.
  ///
  /// On desktop, uses FilePicker.pickFiles() to select a file.
  /// On web, uses the browser file upload dialog.
  Future<void> openProject() async {
    try {
      AppLogger.i('Opening project...');

      // 1. Pick the .zap file.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zap'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      // 2. Read bytes (handles both web and desktop).
      Uint8List bytes;
      if (kIsWeb) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
        _currentFilePath = file.path;
      } else {
        return;
      }

      // 3. Deserialize project.
      final serializer = ProjectSerializer();
      final serialized = await serializer.deserialize(bytes);
      if (serialized == null) {
        AppLogger.e('Failed to deserialize project');
        return;
      }

      // 4. Unload old audio and load new.
      final audioService = ref.read(audioServiceProvider);
      audioService.unloadAll();

      // 5. Apply new project state.
      // Update track audio paths with extracted locations.
      final updatedTracks = serialized.project.tracks.map((t) {
        final audioPath = serialized.trackAudioFiles[t.id];
        return audioPath != null ? t.copyWith(audioFilePath: audioPath) : t;
      }).toList();
      state = serialized.project.copyWith(tracks: updatedTracks);

      // 6. Load audio for each track.
      for (final track in state.tracks) {
        if (track.audioFilePath != null) {
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

  void addTrack({String? name, String? audioFilePath}) {
    final trackColors = [
      const Color(0xFF40C4FF),
      const Color(0xFF69F0AE),
      const Color(0xFFFFD740),
      const Color(0xFFFF8A65),
      const Color(0xFFCE93D8),
      const Color(0xFF4DB6AC),
      const Color(0xFFF06292),
      const Color(0xFFAED581),
    ];

    final track = Track(
      id: _uuid.v4(),
      name: name ?? 'track ${state.tracks.length + 1}',
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
    AppLogger.i('Added track: ${track.name}');
  }

  void removeTrack(String trackId) {
    ref.read(audioServiceProvider).unloadTrack(trackId);
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
    state = state.copyWith(
      tracks: state.tracks.map((t) {
        if (t.id == trackId) return t.copyWith(name: newName);
        return t;
      }).toList(),
    );
  }

  void newProject() {
    ref.read(audioServiceProvider).unloadAll();
    _currentFilePath = null;
    state = Project(id: _uuid.v4(), name: 'Untitled');
    AppLogger.i('New project created');
  }
}

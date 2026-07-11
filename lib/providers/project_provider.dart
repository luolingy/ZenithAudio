import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/track.dart';
import '../core/utils/logger.dart';
import '../services/audio_service.dart';

final projectProvider = NotifierProvider<ProjectNotifier, Project>(
  ProjectNotifier.new,
);

class ProjectNotifier extends Notifier<Project> {
  static const _uuid = Uuid();

  @override
  Project build() {
    return Project(id: _uuid.v4(), name: '未命名项目');
  }

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
      name: name ?? '音轨 ${state.tracks.length + 1}',
      volume: 0.8,
      audioFilePath: audioFilePath,
      color: trackColors[state.tracks.length % trackColors.length],
    );

    state = state.copyWith(tracks: [...state.tracks, track]);
    if (audioFilePath != null) {
      ref.read(audioServiceProvider).loadTrack(track);
    }
    AppLogger.i('添加音轨: ${track.name}');
  }

  void removeTrack(String trackId) {
    ref.read(audioServiceProvider).unloadTrack(trackId);
    final removedName = state.tracks.firstWhere((t) => t.id == trackId).name;
    state = state.copyWith(
      tracks: state.tracks.where((t) => t.id != trackId).toList(),
    );
    AppLogger.i('删除音轨: $removedName');
  }

  void updateTrackVolume(String trackId, double volume) {
    final trackName = state.tracks.firstWhere((t) => t.id == trackId).name;
    state = state.copyWith(
      tracks: state.tracks.map((t) {
        if (t.id == trackId) return t.copyWith(volume: volume);
        return t;
      }).toList(),
    );
    AppLogger.d('音轨 "$trackName" 音量: ${(volume * 100).toInt()}%');
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
    AppLogger.i('音轨 "${track.name}" ${newMuted ? "静音" : "取消静音"}');
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
    AppLogger.i('音轨 "${track.name}" ${newSolo ? "独奏" : "取消独奏"}');
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
    state = Project(id: _uuid.v4(), name: '未命名项目');
    AppLogger.i('新建项目');
  }
}

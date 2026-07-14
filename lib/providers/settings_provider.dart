import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final bool autoLoop;
  final String pianoRollEditMode;
  final bool snapToGrid;
  final double gridResolution;
  final bool autoSaveEnabled;
  final int autoSaveIntervalMinutes;
  final String editorMode;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('zh'),
    this.autoLoop = false,
    this.pianoRollEditMode = 'basic',
    this.snapToGrid = true,
    this.gridResolution = 0.25,
    this.autoSaveEnabled = false,
    this.autoSaveIntervalMinutes = 5,
    this.editorMode = 'fullscreen',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? autoLoop,
    String? pianoRollEditMode,
    bool? snapToGrid,
    double? gridResolution,
    bool? autoSaveEnabled,
    int? autoSaveIntervalMinutes,
    String? editorMode,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      autoLoop: autoLoop ?? this.autoLoop,
      pianoRollEditMode: pianoRollEditMode ?? this.pianoRollEditMode,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      gridResolution: gridResolution ?? this.gridResolution,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      autoSaveIntervalMinutes: autoSaveIntervalMinutes ?? this.autoSaveIntervalMinutes,
      editorMode: editorMode ?? this.editorMode,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadFromPrefs();
    return const SettingsState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeStr = prefs.getString('themeMode') ?? 'system';
    final themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == themeModeStr,
      orElse: () => ThemeMode.system,
    );
    final localeStr = prefs.getString('locale') ?? 'zh';
    final locale = Locale(localeStr);
    state = SettingsState(
      themeMode: themeMode,
      locale: locale,
      autoLoop: prefs.getBool('autoLoop') ?? false,
      pianoRollEditMode: prefs.getString('pianoRollEditMode') ?? 'basic',
      snapToGrid: prefs.getBool('snapToGrid') ?? true,
      gridResolution: prefs.getDouble('gridResolution') ?? 0.25,
      autoSaveEnabled: prefs.getBool('autoSaveEnabled') ?? false,
      autoSaveIntervalMinutes: prefs.getInt('autoSaveIntervalMinutes') ?? 5,
      editorMode: prefs.getString('editorMode') ?? 'fullscreen',
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', state.themeMode.name);
    await prefs.setString('locale', state.locale.toLanguageTag());
    await prefs.setBool('autoLoop', state.autoLoop);
    await prefs.setString('pianoRollEditMode', state.pianoRollEditMode);
    await prefs.setBool('snapToGrid', state.snapToGrid);
    await prefs.setDouble('gridResolution', state.gridResolution);
    await prefs.setBool('autoSaveEnabled', state.autoSaveEnabled);
    await prefs.setInt('autoSaveIntervalMinutes', state.autoSaveIntervalMinutes);
    await prefs.setString('editorMode', state.editorMode);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
    _persist();
  }

  void setAutoLoop(bool value) {
    state = state.copyWith(autoLoop: value);
    _persist();
  }

  void setPianoRollEditMode(String mode) {
    state = state.copyWith(pianoRollEditMode: mode);
    _persist();
  }

  void setSnapToGrid(bool value) {
    state = state.copyWith(snapToGrid: value);
    _persist();
  }

  void setGridResolution(double value) {
    state = state.copyWith(gridResolution: value);
    _persist();
  }

  void setAutoSaveEnabled(bool value) {
    state = state.copyWith(autoSaveEnabled: value);
    _persist();
  }

  void setAutoSaveIntervalMinutes(int value) {
    state = state.copyWith(autoSaveIntervalMinutes: value);
    _persist();
  }

  void setEditorMode(String mode) {
    state = state.copyWith(editorMode: mode);
    _persist();
  }
}

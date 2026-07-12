import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final bool autoLoop;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('zh'),
    this.autoLoop = false,
  });

  SettingsState copyWith({ThemeMode? themeMode, Locale? locale, bool? autoLoop}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      autoLoop: autoLoop ?? this.autoLoop,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
  }

  void setAutoLoop(bool value) {
    state = state.copyWith(autoLoop: value);
  }
}

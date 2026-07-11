import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('zh'),
  });

  SettingsState copyWith({ThemeMode? themeMode, Locale? locale}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
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
}

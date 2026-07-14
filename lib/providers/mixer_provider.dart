import 'package:flutter_riverpod/flutter_riverpod.dart';

final mixerProvider = NotifierProvider<MixerNotifier, MixerState>(
  MixerNotifier.new,
);

final meterLevelsProvider = StateProvider<Map<String, double>>((ref) => {});

class MixerState {
  final bool isExpanded;
  final double masterVolume;
  final Map<String, List<String>> trackFx; // trackId -> fx names

  const MixerState({
    this.isExpanded = true,
    this.masterVolume = 0.8,
    this.trackFx = const {},
  });

  MixerState copyWith({
    bool? isExpanded,
    double? masterVolume,
    Map<String, List<String>>? trackFx,
  }) {
    return MixerState(
      isExpanded: isExpanded ?? this.isExpanded,
      masterVolume: masterVolume ?? this.masterVolume,
      trackFx: trackFx ?? this.trackFx,
    );
  }
}

class MixerNotifier extends Notifier<MixerState> {
  @override
  MixerState build() => const MixerState();

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void setExpanded(bool v) {
    state = state.copyWith(isExpanded: v);
  }

  void setMasterVolume(double v) {
    state = state.copyWith(masterVolume: v.clamp(0.0, 1.0));
  }

  void addFx(String trackId, String fxName) {
    final current = List<String>.from(state.trackFx[trackId] ?? []);
    current.add(fxName);
    state = state.copyWith(
      trackFx: {...state.trackFx, trackId: current},
    );
  }

  void removeFx(String trackId, String fxName) {
    final current = List<String>.from(state.trackFx[trackId] ?? []);
    current.remove(fxName);
    state = state.copyWith(
      trackFx: {...state.trackFx, trackId: current},
    );
  }
}

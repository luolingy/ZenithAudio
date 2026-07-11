import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PlaybackState { stopped, playing, paused }

final playbackProvider = NotifierProvider<PlaybackNotifier, PlaybackState>(
  PlaybackNotifier.new,
);

final playheadPositionProvider = StateProvider<double>((ref) => 0);

class PlaybackNotifier extends Notifier<PlaybackState> {
  @override
  PlaybackState build() => PlaybackState.stopped;

  void play() => state = PlaybackState.playing;
  void pause() => state = PlaybackState.paused;
  void stop() => state = PlaybackState.stopped;
  void toggle() {
    if (state == PlaybackState.playing) {
      state = PlaybackState.paused;
    } else {
      state = PlaybackState.playing;
    }
  }
}

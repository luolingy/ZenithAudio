import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';
import 'settings_provider.dart';

enum PlaybackState { stopped, playing, paused }

final playbackProvider = NotifierProvider<PlaybackNotifier, PlaybackState>(
  PlaybackNotifier.new,
);

final playheadPositionProvider = StateProvider<double>((ref) => 0);

final masterVolumeProvider = StateProvider<double>((ref) => 0.8);

final pixelsPerSecondProvider = StateProvider<double>((ref) => 50.0);

class PlaybackNotifier extends Notifier<PlaybackState> {
  @override
  PlaybackState build() {
    final audio = ref.read(audioServiceProvider);
    audio.onPositionChanged = (pos) {
      ref.read(playheadPositionProvider.notifier).state = pos;
    };
    audio.onCompleted = () {
      // When playback naturally completes, check auto-loop setting.
      final settings = ref.read(settingsProvider);
      if (settings.autoLoop) {
        // Seek to beginning and play again.
        _restart();
      } else {
        state = PlaybackState.stopped;
        ref.read(playheadPositionProvider.notifier).state = 0;
      }
    };
    return PlaybackState.stopped;
  }

  Future<void> _restart() async {
    await ref.read(audioServiceProvider).seekTo(0);
    ref.read(playheadPositionProvider.notifier).state = 0;
    await ref.read(audioServiceProvider).play();
    state = PlaybackState.playing;
  }

  Future<void> play() async {
    await ref.read(audioServiceProvider).play();
    state = PlaybackState.playing;
  }

  Future<void> pause() async {
    await ref.read(audioServiceProvider).pause();
    state = PlaybackState.paused;
  }

  Future<void> stop() async {
    await ref.read(audioServiceProvider).stop();
    ref.read(playheadPositionProvider.notifier).state = 0;
    state = PlaybackState.stopped;
  }

  Future<void> toggle() async {
    if (state == PlaybackState.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekTo(double seconds) async {
    await ref.read(audioServiceProvider).seekTo(seconds);
    ref.read(playheadPositionProvider.notifier).state = seconds;
  }
}

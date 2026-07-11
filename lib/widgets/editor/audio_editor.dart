import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/theme_colors.dart';
import '../../providers/project_provider.dart';
import '../../providers/playback_provider.dart';
import '../toolbar/menu_bar.dart';
import '../toolbar/tool_bar.dart';
import '../controls/transport_bar.dart';
import 'timeline_ruler.dart';
import 'track_panel.dart';
import 'waveform_view.dart';

class AudioEditor extends ConsumerWidget {
  const AudioEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    final playhead = ref.watch(playheadPositionProvider);
    final screenSize = getScreenSize(context);

    final pixelsPerSecond = switch (screenSize) {
      ScreenSize.mobile => 30.0,
      ScreenSize.tablet => 40.0,
      ScreenSize.desktop => 50.0,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          if (screenSize != ScreenSize.mobile) const AudioMenuBar(),
          const AudioToolBar(),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (screenSize != ScreenSize.mobile)
                      const SizedBox(width: AppConstants.trackPanelWidth),
                    Expanded(
                      child: ClipRect(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: TimelineRuler(
                            duration: project.duration > 0 ? project.duration : 60,
                            pixelsPerSecond: pixelsPerSecond,
                            currentPosition: playhead,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    children: [
                      const TrackPanel(),
                      Expanded(
                        child: ClipRect(
                          child: project.tracks.isEmpty
                              ? _buildEmptyState(context)
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: (project.duration > 0
                                            ? project.duration
                                            : 60) *
                                        pixelsPerSecond,
                                    child: ListView.builder(
                                      itemCount: project.tracks.length,
                                      itemExtent: AppConstants.trackTileHeight,
                                      itemBuilder: (context, index) {
                                        return WaveformView(
                                          track: project.tracks[index],
                                          pixelsPerSecond: pixelsPerSecond,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const TransportBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.waves_outlined, size: 64,
              color: context.outline.withAlpha(77)),
          const SizedBox(height: 16),
          Text('editor.emptyTitle'.tr(),
              style: TextStyle(color: context.outline.withAlpha(153), fontSize: 14)),
          const SizedBox(height: 8),
          Text('editor.emptySubtitle'.tr(),
              style: TextStyle(color: context.outline.withAlpha(102), fontSize: 11)),
        ],
      ),
    );
  }
}

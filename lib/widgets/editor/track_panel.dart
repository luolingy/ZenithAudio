import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/theme_colors.dart';
import '../../providers/project_provider.dart';
import '../../core/utils/responsive_utils.dart';
import 'track_tile.dart';

class TrackPanel extends ConsumerWidget {
  const TrackPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    final screenSize = getScreenSize(context);
    final cs = Theme.of(context).colorScheme;

    final panelWidth = switch (screenSize) {
      ScreenSize.mobile => 180.0,
      ScreenSize.tablet => 200.0,
      ScreenSize.desktop => AppConstants.trackPanelWidth,
    };

    return Container(
      width: panelWidth,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: AppConstants.timelineHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: context.surfaceLight,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              'track.header'.tr(),
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: project.tracks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note_outlined,
                          size: 32,
                          color: context.textDim.withAlpha(128),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'track.empty'.tr(),
                          style: TextStyle(color: context.textDim, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'track.emptyHint'.tr(),
                          style: TextStyle(
                            color: context.textDim.withAlpha(153),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: project.tracks.length,
                    itemExtent: AppConstants.trackTileHeight,
                    itemBuilder: (context, index) => TrackTile(
                      track: project.tracks[index],
                      index: index,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

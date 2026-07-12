import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/project_provider.dart';
import '../../providers/playback_provider.dart';
import '../../core/utils/logger.dart';

class AudioToolBar extends ConsumerWidget {
  const AudioToolBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: AppConstants.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _ToolButton(
            icon: Icons.note_add_outlined,
            tooltip: 'toolbar.newProject'.tr(),
            onTap: () {
              ref.read(projectProvider.notifier).newProject();
              AppLogger.i('New project');
            },
          ),
          _ToolButton(
            icon: Icons.folder_open_outlined,
            tooltip: 'toolbar.openProject'.tr(),
            onTap: () async {
              final notifier = ref.read(projectProvider.notifier);
              await notifier.openProject();
            },
          ),
          _ToolButton(
            icon: Icons.save_outlined,
            tooltip: 'toolbar.saveProject'.tr(),
            onTap: () async {
              final notifier = ref.read(projectProvider.notifier);
              await notifier.saveProject();
            },
          ),
          const _ToolDivider(),
          _ToolButton(
            icon: Icons.undo_outlined,
            tooltip: 'toolbar.undo'.tr(),
          ),
          _ToolButton(
            icon: Icons.redo_outlined,
            tooltip: 'toolbar.redo'.tr(),
          ),
          const _ToolDivider(),
          _ToolButton(
            icon: Icons.content_cut_outlined,
            tooltip: 'toolbar.cut'.tr(),
          ),
          _ToolButton(
            icon: Icons.content_copy_outlined,
            tooltip: 'toolbar.copy'.tr(),
          ),
          _ToolButton(
            icon: Icons.content_paste_outlined,
            tooltip: 'toolbar.paste'.tr(),
          ),
          const _ToolDivider(),
          _ToolButton(
            icon: Icons.add,
            tooltip: 'toolbar.addTrack'.tr(),
            onTap: () {
              final trackIndex = ref.read(projectProvider).tracks.length + 1;
              final name = 'Track $trackIndex';
              ref.read(projectProvider.notifier).addTrack(name: name);
              AppLogger.i('Added audio track: $name');
            },
          ),
          _ToolButton(
            icon: Icons.piano_outlined,
            tooltip: 'toolbar.addInstrumentTrack'.tr(),
            onTap: () {
              final trackIndex = ref.read(projectProvider).tracks.length + 1;
              final name = 'Track $trackIndex';
              ref.read(projectProvider.notifier).addInstrumentTrack(name: name);
              AppLogger.i('Added instrument track: $name');
            },
          ),
          _ToolButton(
            icon: Icons.remove,
            tooltip: 'toolbar.deleteTrack'.tr(),
          ),
          const Spacer(),
          _ToolButton(
            icon: Icons.zoom_in_outlined,
            tooltip: 'toolbar.zoomIn'.tr(),
            onTap: () {
              final cur = ref.read(pixelsPerSecondProvider);
              ref.read(pixelsPerSecondProvider.notifier).state =
                  (cur * 1.25).clamp(10, 500);
            },
          ),
          _ToolButton(
            icon: Icons.zoom_out_outlined,
            tooltip: 'toolbar.zoomOut'.tr(),
            onTap: () {
              final cur = ref.read(pixelsPerSecondProvider);
              ref.read(pixelsPerSecondProvider.notifier).state =
                  (cur / 1.25).clamp(10, 500);
            },
          ),
          _ToolButton(
            icon: Icons.fit_screen_outlined,
            tooltip: 'toolbar.fitWindow'.tr(),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ToolButton({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, size: 18, color: cs.onSurfaceVariant),
            padding: EdgeInsets.zero,
            splashRadius: 16,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolDivider extends StatelessWidget {
  const _ToolDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context).dividerColor,
    );
  }
}

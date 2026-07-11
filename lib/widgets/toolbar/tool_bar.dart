import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/theme_colors.dart';
import '../../providers/project_provider.dart';
import '../../providers/playback_provider.dart';
import '../../services/file_service.dart';
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
              AppLogger.i('新建项目');
            },
          ),
          _ToolButton(
            icon: Icons.file_open_outlined,
            tooltip: 'toolbar.importAudio'.tr(),
            onTap: () async {
              final fileService = FileService();
              final path = await fileService.pickAudioFile();
              if (path != null && context.mounted) {
                final trackIndex = ref.read(projectProvider).tracks.length + 1;
                final name = 'track.defaultName'.tr(namedArgs: {'n': '$trackIndex'});
                ref.read(projectProvider.notifier).addTrack(
                      name: name,
                      audioFilePath: path,
                    );
                AppLogger.i('导入音频: $path');
              }
            },
          ),
          _ToolButton(
            icon: Icons.save_outlined,
            tooltip: 'toolbar.save'.tr(),
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
              final name = 'track.defaultName'.tr(namedArgs: {'n': '$trackIndex'});
              ref.read(projectProvider.notifier).addTrack(name: name);
              AppLogger.i('添加音轨: $name');
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            hoverColor: context.surfaceHigh,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
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

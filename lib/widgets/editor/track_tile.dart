import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/theme_colors.dart';
import '../../models/track.dart';
import '../../providers/project_provider.dart';

String _formatDuration(double sec) {
  final m = (sec ~/ 60).toString().padLeft(2, '0');
  final s = (sec % 60).toStringAsFixed(1).padLeft(4, '0');
  return '$m:$s';
}

class TrackTile extends ConsumerWidget {
  final Track track;
  final int index;

  const TrackTile({
    super.key,
    required this.track,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSolo = ref.watch(projectProvider).hasSoloTrack;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showContextMenu(context, ref, details.localPosition),
      onLongPressStart: (details) =>
          _showContextMenu(context, ref, details.localPosition),
      child: Container(
        height: AppConstants.trackTileHeight,
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 1),
        decoration: BoxDecoration(
          color: _getBackgroundColor(context, hasSolo),
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor.withAlpha(128)),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: track.color.withAlpha(38),
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor.withAlpha(77)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 16,
                    decoration: BoxDecoration(
                      color: track.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      track.name,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.volume_up_outlined,
                            size: 12, color: context.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: SizedBox(
                            height: 20,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 10),
                              ),
                              child: Slider(
                                value: track.volume,
                                min: 0, max: 1, divisions: 100,
                                onChanged: (v) => ref
                                    .read(projectProvider.notifier)
                                    .updateTrackVolume(track.id, v),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${(track.volume * 100).toInt()}%',
                          style: TextStyle(color: context.outline, fontSize: 9),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _ControlButton(
                          label: 'M',
                          isActive: track.isMuted,
                          activeColor: AppColors.mute,
                          onTap: () => ref
                              .read(projectProvider.notifier)
                              .toggleTrackMute(track.id),
                        ),
                        const SizedBox(width: 4),
                        _ControlButton(
                          label: 'S',
                          isActive: track.isSolo,
                          activeColor: AppColors.solo,
                          onTap: () => ref
                              .read(projectProvider.notifier)
                              .toggleTrackSolo(track.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context, bool hasSolo) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    if (hasSolo && !track.isSolo) return bg.withAlpha(128);
    if (track.isMuted) return bg.withAlpha(179);
    return bg;
  }

  void _showContextMenu(BuildContext context, WidgetRef ref, Offset localPos) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final globalPos = renderBox.localToGlobal(localPos);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          globalPos.dx, globalPos.dy, globalPos.dx + 1, globalPos.dy + 1),
      items: [
        const PopupMenuItem(value: 'rename', child: Text('重命名')),
        const PopupMenuItem(value: 'properties', child: Text('属性')),
        const PopupMenuItem(value: 'delete', child: Text('删除')),
      ],
    ).then((value) {
      switch (value) {
        case 'rename':
          _showRenameDialog(context, ref);
        case 'properties':
          _showPropertiesDialog(context);
        case 'delete':
          _showDeleteDialog(context, ref);
      }
    });
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: track.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名音轨'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '音轨名称'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('确定')),
        ],
      ),
    );
    controller.dispose();
    if (newName != null && newName.trim().isNotEmpty) {
      ref.read(projectProvider.notifier).renameTrack(track.id, newName.trim());
    }
  }

  void _showPropertiesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('音轨属性'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('名称: ${track.name}'),
            const SizedBox(height: 8),
            Text('时长: ${_formatDuration(track.duration)}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('确定')),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除音轨'),
        content: Text('确定删除音轨 "${track.name}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('删除',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(projectProvider.notifier).removeTrack(track.id);
    }
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ControlButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withAlpha(51)
              : context.surfaceHigh,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isActive ? activeColor : Theme.of(context).dividerColor,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : context.outline,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/theme_colors.dart';
import '../../providers/project_provider.dart';
import '../../providers/playback_provider.dart';
import '../../services/file_service.dart';
import '../../screens/settings_page.dart';
import '../../screens/about_dialog.dart' as app;
import '../../core/utils/logger.dart';

class AudioMenuBar extends ConsumerWidget {
  const AudioMenuBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: AppConstants.menuBarHeight,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _MenuButton(
            label: 'menu.file'.tr(),
            items: [
              MenuItem(
                label: 'menu.file.newProject'.tr(),
                shortcut: 'shortcut.newProject'.tr(),
                onTap: () {
                  ref.read(projectProvider.notifier).newProject();
                  AppLogger.i('新建项目');
                },
              ),
              MenuItem(
                label: 'menu.file.importAudio'.tr(),
                shortcut: 'shortcut.importAudio'.tr(),
                onTap: () async {
                  final fileService = FileService();
                  final result = await fileService.pickAudioFile();
                  if (result != null && context.mounted) {
                    final trackIndex = ref.read(projectProvider).tracks.length + 1;
                    final name = 'track.defaultName'.tr(namedArgs: {'n': '$trackIndex'});
                    ref.read(projectProvider.notifier).addTrack(
                          name: name,
                          audioFilePath: result.audioSource,
                        );
                    AppLogger.i('导入音频: ${result.name}');
                  }
                },
              ),
              MenuItem.separator(),
              MenuItem(
                label: 'menu.file.exportMix'.tr(),
                shortcut: 'shortcut.exportMix'.tr(),
              ),
              MenuItem.separator(),
              MenuItem(
                label: 'menu.file.settings'.tr(),
                onTap: () => _showSettings(context),
              ),
              MenuItem.separator(),
              MenuItem(
                label: 'menu.file.exit'.tr(),
                shortcut: 'shortcut.exit'.tr(),
              ),
            ],
          ),
          _MenuButton(
            label: 'menu.edit'.tr(),
            items: [
              MenuItem(
                label: 'menu.edit.undo'.tr(),
                shortcut: 'shortcut.undo'.tr(),
              ),
              MenuItem(
                label: 'menu.edit.redo'.tr(),
                shortcut: 'shortcut.redo'.tr(),
              ),
              const MenuItem.separator(),
              MenuItem(label: 'menu.edit.deleteTrack'.tr()),
            ],
          ),
          _MenuButton(
            label: 'menu.track'.tr(),
            items: [
              MenuItem(
                label: 'menu.track.add'.tr(),
                shortcut: 'shortcut.addTrack'.tr(),
                onTap: () {
                  final trackIndex = ref.read(projectProvider).tracks.length + 1;
                  final name = 'track.defaultName'.tr(namedArgs: {'n': '$trackIndex'});
                  ref.read(projectProvider.notifier).addTrack(name: name);
                  AppLogger.i('添加音轨: $name');
                },
              ),
              MenuItem(label: 'menu.track.rename'.tr()),
              const MenuItem.separator(),
              MenuItem(label: 'menu.track.muteAll'.tr()),
              MenuItem(label: 'menu.track.unmuteAll'.tr()),
            ],
          ),
          _MenuButton(
            label: 'menu.view'.tr(),
            items: [
              MenuItem(
                label: 'menu.view.zoomIn'.tr(),
                onTap: () {
                  final cur = ref.read(pixelsPerSecondProvider);
                  ref.read(pixelsPerSecondProvider.notifier).state =
                      (cur * 1.25).clamp(10, 500);
                },
              ),
              MenuItem(
                label: 'menu.view.zoomOut'.tr(),
                onTap: () {
                  final cur = ref.read(pixelsPerSecondProvider);
                  ref.read(pixelsPerSecondProvider.notifier).state =
                      (cur / 1.25).clamp(10, 500);
                },
              ),
              MenuItem(label: 'menu.view.fitWindow'.tr()),
            ],
          ),
          _MenuButton(
            label: 'menu.help'.tr(),
            items: [
              MenuItem(
                label: 'menu.help.about'.tr(),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const app.AboutDialog(),
                ),
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              AppConstants.appNameEn,
              style: TextStyle(
                color: cs.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }
}

class MenuItem {
  final String label;
  final String? shortcut;
  final VoidCallback? onTap;
  final bool isSeparator;

  const MenuItem({required this.label, this.shortcut, this.onTap, this.isSeparator = false});
  const MenuItem.separator()
      : label = '',
        shortcut = null,
        onTap = null,
        isSeparator = true;
}

class _MenuButton extends StatefulWidget {
  final String label;
  final List<MenuItem> items;

  const _MenuButton({required this.label, required this.items});

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _isHovered = false;
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          setState(() => _isOpen = !_isOpen);
          if (_isOpen) {
            _showMenu(context);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHovered ? context.surfaceHigh : Colors.transparent,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _isHovered ? cs.onSurface : cs.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) async {
    await showMenu<MenuItem>(
      context: context,
      position: RelativeRect.fromLTRB(
        _getPosition(), 0, _getPosition() + 100, 0,
      ),
      initialValue: null,
      items: [
        for (final item in widget.items)
          if (item.isSeparator)
            const PopupMenuDivider(height: 1)
          else
            PopupMenuItem<MenuItem>(
              value: item,
              enabled: item.onTap != null,
              onTap: item.onTap,
              height: 28,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.label, style: const TextStyle(fontSize: 12)),
                  if (item.shortcut != null) ...[
                    const Spacer(),
                    Text(
                      item.shortcut!,
                      style: TextStyle(fontSize: 10, color: context.outline),
                    ),
                  ],
                ],
              ),
            ),
      ],
    );
    setState(() => _isOpen = false);
  }

  double _getPosition() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return 0;
    return box.localToGlobal(Offset.zero).dx;
  }
}

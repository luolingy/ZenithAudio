import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_constants.dart';
import '../../core/instrument_picker.dart';
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
            onTap: () => ref.read(projectProvider.notifier).undo(),
          ),
          _ToolButton(
            icon: Icons.redo_outlined,
            tooltip: 'toolbar.redo'.tr(),
            onTap: () => ref.read(projectProvider.notifier).redo(),
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
            onTap: () async {
              final instrument = await showInstrumentPicker(context);
              if (instrument == null) return;
              final trackIndex = ref.read(projectProvider).tracks.length + 1;
              final name = 'Track $trackIndex';
              ref.read(projectProvider.notifier).addInstrumentTrack(name: name, instrumentName: instrument);
              AppLogger.i('Added instrument track: $name ($instrument)');
            },
          ),
          _ToolButton(
            icon: Icons.remove,
            tooltip: 'toolbar.deleteTrack'.tr(),
          ),
          const Spacer(),
          // Project settings (time sig, key sig, BPM, speed)
          _ProjectSettingsButton(),
          const _ToolDivider(),
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

/// Consolidated project settings popup button (time sig, key sig, BPM, speed).
class _ProjectSettingsButton extends ConsumerWidget {
  static const _keys = ['C', 'G', 'D', 'A', 'E', 'B', 'F#', 'C#', 'F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ToolButton(
      icon: Icons.tune_outlined,
      tooltip: 'Project Settings',
      onTap: () => _showSettingsDialog(context, ref),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final bpmCtrl = TextEditingController(text: ref.read(projectProvider).bpm.round().toString());
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final proj = ref.watch(projectProvider);
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.tune, size: 18),
                const SizedBox(width: 8),
                const Text('Project Settings'),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Time Signature ──
                    Text('Time Signature', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: '${proj.timeSignatureNumerator}/${proj.timeSignatureDenominator}',
                      isExpanded: true,
                      items: ['2/4', '3/4', '4/4', '5/4', '6/8']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final parts = v.split('/');
                        ref.read(projectProvider.notifier)
                            .setTimeSignature(int.parse(parts[0]), int.parse(parts[1]));
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Key Signature ──
                    Text('Key Signature', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: proj.keySignature,
                      isExpanded: true,
                      items: _keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                      onChanged: (v) {
                        if (v != null) ref.read(projectProvider.notifier).setKeySignature(v);
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── BPM ──
                    Row(
                      children: [
                        Text('BPM', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: bpmCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (v) {
                              final val = double.tryParse(v);
                              if (val != null) {
                                ref.read(projectProvider.notifier).setBpm(val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: proj.bpm,
                      min: 20,
                      max: 300,
                      onChanged: (v) {
                        bpmCtrl.text = v.round().toString();
                        bpmCtrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: bpmCtrl.text.length),
                        );
                        ref.read(projectProvider.notifier).setBpm(v);
                      },
                    ),
                    const SizedBox(height: 8),

                    // ── Playback Speed ──
                    Row(
                      children: [
                        Text('Speed', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        const Spacer(),
                        Text('${proj.playbackSpeed.toStringAsFixed(2)}x',
                            style: TextStyle(fontSize: 12, color: cs.onSurface)),
                      ],
                    ),
                    Slider(
                      value: proj.playbackSpeed,
                      min: 0.25,
                      max: 4.0,
                      divisions: 15,
                      onChanged: (v) =>
                          ref.read(projectProvider.notifier).setPlaybackSpeed(v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}

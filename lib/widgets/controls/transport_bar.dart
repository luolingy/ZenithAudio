import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/theme_colors.dart';
import '../../providers/playback_provider.dart';
import '../../core/utils/logger.dart';

class TransportBar extends ConsumerWidget {
  const TransportBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: AppConstants.transportBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _TransportButton(
            icon: Icons.skip_previous_rounded,
            tooltip: 'transport.skipStart'.tr(),
            onTap: () {
              ref.read(playheadPositionProvider.notifier).state = 0;
              AppLogger.i('跳到开头');
            },
          ),
          const SizedBox(width: 4),
          _TransportButton(
            icon: playbackState == PlaybackState.playing
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            tooltip: playbackState == PlaybackState.playing
                ? 'transport.pause'.tr()
                : 'transport.play'.tr(),
            size: 32, iconSize: 24, isPrimary: true,
            onTap: () {
              ref.read(playbackProvider.notifier).toggle();
              AppLogger.i(playbackState == PlaybackState.playing ? '暂停' : '播放');
            },
          ),
          const SizedBox(width: 4),
          _TransportButton(
            icon: Icons.stop_rounded,
            tooltip: 'transport.stop'.tr(),
            onTap: () {
              ref.read(playbackProvider.notifier).stop();
              AppLogger.i('停止');
            },
          ),
          const SizedBox(width: 4),
          _TransportButton(
            icon: Icons.skip_next_rounded,
            tooltip: 'transport.skipEnd'.tr(),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(
              '00:00.0 / 00:00.0',
              style: TextStyle(
                color: cs.primary,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          Icon(Icons.volume_up_outlined, size: 16, color: context.outline),
          const SizedBox(width: 6),
          SizedBox(
            width: 100,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                value: 0.8, min: 0, max: 1, onChanged: null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final bool isPrimary;

  const _TransportButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.size = 28,
    this.iconSize = 18,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(isPrimary ? 16 : 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isPrimary ? 16 : 4),
          hoverColor: isPrimary
              ? cs.primary.withAlpha(204)
              : context.surfaceHigh,
          child: Container(
            width: size, height: size,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: iconSize,
              color: isPrimary
                  ? Theme.of(context).scaffoldBackgroundColor
                  : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Toolbar for the audio clip editor, styled like [AudioToolBar].
class AudioClipToolbar extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  final void Function(String action) onProcess;
  final VoidCallback? onFrequencySplit;

  final bool showGenerator;
  final VoidCallback onToggleGenerator;
  final bool showSpectrogram;
  final VoidCallback onToggleSpectrogram;

  final double zoom;
  final ValueChanged<double> onZoomChanged;

  const AudioClipToolbar({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onProcess,
    this.onFrequencySplit,
    required this.showGenerator,
    required this.onToggleGenerator,
    required this.showSpectrogram,
    required this.onToggleSpectrogram,
    required this.zoom,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // Undo / Redo
            _toolBtn(
              context,
              icon: Icons.undo,
              tooltip: 'audioClip.undo'.tr(),
              onTap: canUndo ? onUndo : null,
            ),
            _toolBtn(
              context,
              icon: Icons.redo,
              tooltip: 'audioClip.redo'.tr(),
              onTap: canRedo ? onRedo : null,
            ),
            _divider(context),

            // Simple one-click effects
            _toolBtn(
              context,
              icon: Icons.vertical_align_center,
              tooltip: 'audioClip.normalize'.tr(),
              onTap: () => onProcess('normalize'),
            ),
            _toolBtn(
              context,
              icon: Icons.replay,
              tooltip: 'audioClip.reverse'.tr(),
              onTap: () => onProcess('reverse'),
            ),
            _toolBtn(
              context,
              icon: Icons.block,
              tooltip: 'audioClip.removeDc'.tr(),
              onTap: () => onProcess('removeDc'),
            ),
            _toolBtn(
              context,
              icon: Icons.flip_to_front,
              tooltip: 'audioClip.invert'.tr(),
              onTap: () => onProcess('invert'),
            ),
            _divider(context),

            // View toggles
            _toolBtn(
              context,
              icon: showGenerator ? Icons.expand_more : Icons.expand_less,
              tooltip: 'audioClip.generator'.tr(),
              onTap: onToggleGenerator,
            ),
            _toolBtn(
              context,
              icon: showSpectrogram ? Icons.wifi : Icons.wifi_outlined,
              tooltip: 'audioClip.spectrogram'.tr(),
              onTap: onToggleSpectrogram,
            ),
            _divider(context),

            // Effects
            _effectButtons(context),

            // Frequency split button
            _toolBtn(
              context,
              icon: Icons.call_split,
              tooltip: 'audioClip.frequencySplit'.tr(),
              onTap: onFrequencySplit,
            ),
            _divider(context),

            // Zoom
            SizedBox(
              width: 80,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                ),
                child: Slider(
                  value: zoom,
                  min: 0.5,
                  max: 10,
                  onChanged: onZoomChanged,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text('${(zoom * 100).round()}%',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _effectButtons(BuildContext context) {
    final effects = <_EffectDef>[
      _EffectDef('compressor', Icons.compress, 'audioClip.effect.compressor'),
      _EffectDef('echo', Icons.repeat_one, 'audioClip.effect.echo'),
      _EffectDef('reverb', Icons.speaker, 'audioClip.effect.reverb'),
      _EffectDef('delay', Icons.timeline, 'audioClip.effect.delay'),
      _EffectDef('equalizer', Icons.tune, 'audioClip.effect.equalizer'),
      _EffectDef('pitchShift', Icons.swap_vert, 'audioClip.effect.pitchShift'),
      _EffectDef('doppler', Icons.waves, 'audioClip.effect.doppler'),
      _EffectDef('fadeIn', Icons.arrow_forward, 'audioClip.effect.fadeIn'),
      _EffectDef('fadeOut', Icons.arrow_back, 'audioClip.effect.fadeOut'),
      _EffectDef('distort', Icons.bolt, 'audioClip.effect.distort'),
      _EffectDef('amplitudeMap', Icons.transform, 'audioClip.effect.amplitudeMap'),
      _EffectDef('mechanize', Icons.memory, 'audioClip.effect.mechanize'),
      _EffectDef('spectrumFilter', Icons.filter_vintage, 'audioClip.effect.spectrumFilter'),
      _EffectDef('splitByFreq', Icons.call_split, 'audioClip.effect.splitByFreq'),
      _EffectDef('splitByTime', Icons.call_split, 'audioClip.effect.splitByTime'),
      _EffectDef('mixer', Icons.queue_music, 'audioClip.effect.mixer'),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: effects.map((e) {
        return _effBtn(context, e);
      }).toList(),
    );
  }

  Widget _effBtn(BuildContext context, _EffectDef e) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Tooltip(
        message: e.tooltipKey.tr(),
        child: SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            onPressed: () => onProcess(e.action),
            icon: Icon(e.icon, size: 16),
            padding: EdgeInsets.zero,
            splashRadius: 14,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolBtn(BuildContext context, {required IconData icon, required String tooltip, VoidCallback? onTap}) {
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
            icon: Icon(icon, size: 18, color: onTap != null ? cs.onSurfaceVariant : cs.onSurfaceVariant.withAlpha(80)),
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

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context).dividerColor,
    );
  }
}

class _EffectDef {
  final String action;
  final IconData icon;
  final String tooltipKey;
  const _EffectDef(this.action, this.icon, this.tooltipKey);
}

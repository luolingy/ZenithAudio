import 'package:flutter/material.dart';
import '../../models/track.dart';

/// Placeholder zone for an instrument track in the main workspace.
///
/// Shows a subtle grid hint and prompts the user to double-tap to open
/// the full-screen piano roll editor.
class PianoRollTrack extends StatelessWidget {
  final Track track;
  final double pixelsPerSecond;
  final VoidCallback? onEdit;

  const PianoRollTrack({
    super.key,
    required this.track,
    this.pixelsPerSecond = 50,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceContainerLow;

    return GestureDetector(
      onDoubleTap: onEdit,
      onTap: onEdit,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor.withAlpha(77)),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.piano_outlined, size: 28, color: track.color.withAlpha(153)),
              const SizedBox(height: 4),
              Text(
                '${track.notes.length} notes',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                'tap to edit',
                style: TextStyle(color: cs.outline.withAlpha(153), fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class LedIndicator extends StatelessWidget {
  final bool active;
  final Color activeColor;
  final Color? inactiveColor;
  final double size;

  const LedIndicator({
    super.key,
    required this.active,
    this.activeColor = const Color(0xFF00FF44),
    this.inactiveColor,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final offColor = inactiveColor ?? cs.surfaceContainerHighest;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? activeColor : offColor,
        shape: BoxShape.circle,
        boxShadow: active
            ? [BoxShadow(color: activeColor.withAlpha(120), blurRadius: 4, spreadRadius: 1)]
            : null,
      ),
    );
  }
}

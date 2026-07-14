import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

extension ZenithThemeColors on BuildContext {
  Color get surfaceHigh => Theme.of(this).colorScheme.surfaceContainerHigh;
  Color get outline => Theme.of(this).colorScheme.outline;

  Color ledOnColor(Color base) => base.withAlpha(220);
  Color get ledOffColor => const Color(0xFF2A2A2A);

  Color channelColor(int index) =>
      AppColors.trackColors[index % AppColors.trackColors.length];
}

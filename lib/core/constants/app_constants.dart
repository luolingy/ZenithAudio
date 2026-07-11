import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = '卓声';
  static const String appNameEn = 'ZENITH AUDIO';

  static const double trackPanelWidth = 220;
  static const double trackTileHeight = 80;
  static const double timelineHeight = 32;
  static const double toolbarHeight = 40;
  static const double menuBarHeight = 28;
  static const double transportBarHeight = 48;

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static const List<String> supportedAudioFormats = [
    '.wav', '.mp3', '.flac', '.aac', '.ogg', '.m4a',
  ];
}

class AppColors {
  AppColors._();

  static const Color accent = Color(0xFF00BFA5);
  static const Color accentDim = Color(0xFF00897B);
  static const Color solo = Color(0xFFFFD740);
  static const Color mute = Color(0xFFFF5252);
  static const Color playhead = Color(0xFFFF5252);
  static const Color waveform = Color(0xFF40C4FF);
  static const Color waveformFill = Color(0x3340C4FF);

  static const List<Color> trackColors = [
    Color(0xFF40C4FF),
    Color(0xFF69F0AE),
    Color(0xFFFFD740),
    Color(0xFFFF8A65),
    Color(0xFFCE93D8),
    Color(0xFF4DB6AC),
    Color(0xFFF06292),
    Color(0xFFAED581),
  ];
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:media_kit/media_kit.dart';
import 'core/utils/logger.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  AppLogger.i('卓声 ZENITH AUDIO 启动');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  FlutterError.onError = (details) {
    AppLogger.e('Flutter 错误', details.exception, details.stack);
    FlutterError.presentError(details);
  };

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('平台错误', error, stack);
    return true;
  };

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('zh'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('zh'),
      startLocale: const Locale('zh'),
      child: const ProviderScope(
        child: ZenithAudioApp(),
      ),
    ),
  );
}

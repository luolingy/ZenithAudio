import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/editor_screen.dart';

class ZenithAudioApp extends ConsumerWidget {
  const ZenithAudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: '${AppConstants.appName} - ${AppConstants.appNameEn}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const EditorScreen(),
    );
  }
}

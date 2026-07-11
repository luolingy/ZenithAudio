import 'package:flutter/material.dart';
import '../editor/audio_editor.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return const AudioEditor();
      },
    );
  }
}

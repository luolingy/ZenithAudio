import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'audio_cache.dart';
import 'platform_dir.dart';

class PickAudioResult {
  final String name;
  final String audioSource;

  PickAudioResult({required this.name, required this.audioSource});
}

class FileService {
  Future<PickAudioResult?> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'flac', 'aac', 'ogg', 'm4a'],
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;

    if (kIsWeb) {
      if (file.bytes != null) {
        final cache = AudioCache();
        final url = await cache.storeAndCreateUrl(file.name, file.bytes!);
        return PickAudioResult(name: file.name, audioSource: url);
      }
      return null;
    }

    if (file.path != null) {
      return PickAudioResult(name: file.name, audioSource: file.path!);
    }

    return null;
  }

  Future<String> getExportDirectory() async {
    return PlatformDir.getDocumentsPath('ZenithAudio');
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FileService {
  Future<String?> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'flac', 'aac', 'ogg', 'm4a'],
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    }
    return null;
  }

  Future<String> getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/ZenithAudio');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }
}

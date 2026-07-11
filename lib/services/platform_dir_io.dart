import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PlatformDir {
  static Future<String> getDocumentsPath(String subdir) async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory('${directory.path}/$subdir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }
}

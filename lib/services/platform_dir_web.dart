class PlatformDir {
  static Future<String> getDocumentsPath(String subdir) async {
    return '/$subdir';
  }
}

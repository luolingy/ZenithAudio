import 'dart:typed_data';

class AudioCache {
  static final AudioCache _instance = AudioCache._();
  factory AudioCache() => _instance;
  AudioCache._();

  Future<Uint8List?> get(String key) async => null;
  Future<void> put(String key, Uint8List bytes) async {}
  Future<void> remove(String key) async {}
  Future<Map<String, Uint8List>> getAll() async => {};
  Future<int> getStorageUsed() async => 0;

  Future<String> storeAndCreateUrl(String name, Uint8List bytes) async {
    throw UnsupportedError('只在网页版使用');
  }
}

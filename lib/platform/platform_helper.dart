import 'platform_stub.dart'
    if (dart.library.io) 'platform_native.dart'
    if (dart.library.html) 'platform_web.dart';

abstract class PlatformHelper {
  static final PlatformHelper instance = createPlatformHelper();

  Future<String> getAppDocumentsPath();
  Future<void> createDirectory(String path);
  Future<bool> directoryExists(String path);
  Future<bool> fileExists(String path);
  Future<void> writeFile(String path, List<int> bytes);
  Future<List<int>?> readFile(String path);
  bool get isWeb;
}

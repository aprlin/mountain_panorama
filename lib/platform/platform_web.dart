import 'platform_helper.dart';

PlatformHelper createPlatformHelper() => PlatformWeb();

class PlatformWeb implements PlatformHelper {
  @override
  Future<String> getAppDocumentsPath() async => '/tmp';

  @override
  Future<void> createDirectory(String path) async {
    // No-op on web
  }

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  Future<void> writeFile(String path, List<int> bytes) async {
    // No-op on web
  }

  @override
  Future<List<int>?> readFile(String path) async => null;

  @override
  bool get isWeb => true;
}

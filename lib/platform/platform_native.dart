import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'platform_helper.dart';

PlatformHelper createPlatformHelper() => PlatformNative();

class PlatformNative implements PlatformHelper {
  @override
  Future<String> getAppDocumentsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  @override
  Future<void> createDirectory(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
  }

  @override
  Future<bool> directoryExists(String path) async {
    return Directory(path).existsSync();
  }

  @override
  Future<bool> fileExists(String path) async {
    return File(path).existsSync();
  }

  @override
  Future<void> writeFile(String path, List<int> bytes) async {
    await File(path).writeAsBytes(bytes);
  }

  @override
  Future<List<int>?> readFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsBytesSync();
  }

  @override
  bool get isWeb => false;
}

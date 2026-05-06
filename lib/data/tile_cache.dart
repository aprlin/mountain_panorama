import 'dart:io';
import 'package:path/path.dart' as p;

class TileCache {
  final String tileDirectory;
  final int maxTiles;

  TileCache({required this.tileDirectory, this.maxTiles = 500});

  /// Get list of cached tile keys sorted by last modified (oldest first).
  List<String> _cachedTileKeys() {
    final dir = Directory(tileDirectory);
    if (!dir.existsSync()) return [];

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.hgt'))
        .toList();

    files.sort((a, b) =>
        a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    return files.map((f) =>
        p.basenameWithoutExtension(f.path)).toList();
  }

  /// Evict oldest tiles if cache exceeds maxTiles.
  int evictIfNeeded() {
    final keys = _cachedTileKeys();
    if (keys.length <= maxTiles) return 0;

    final toRemove = keys.length - maxTiles;
    int removed = 0;

    for (int i = 0; i < toRemove; i++) {
      final file = File(p.join(tileDirectory, '${keys[i]}.hgt'));
      if (file.existsSync()) {
        file.deleteSync();
        removed++;
      }
    }

    return removed;
  }

  /// Get cache size in bytes.
  int cacheSizeBytes() {
    final dir = Directory(tileDirectory);
    if (!dir.existsSync()) return 0;

    int total = 0;
    for (final entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('.hgt')) {
        total += entity.lengthSync();
      }
    }
    return total;
  }

  /// Get number of cached tiles.
  int get tileCount => _cachedTileKeys().length;

  /// Clear all cached tiles.
  void clear() {
    final dir = Directory(tileDirectory);
    if (!dir.existsSync()) return;

    for (final entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('.hgt')) {
        entity.deleteSync();
      }
    }
  }
}

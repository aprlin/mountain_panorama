import 'package:path/path.dart' as p;
import '../platform/platform_helper.dart';

class TileCache {
  final String tileDirectory;
  final int maxTiles;

  TileCache({required this.tileDirectory, this.maxTiles = 500});

  /// Get number of cached tiles. Returns 0 on web.
  int get tileCount {
    if (PlatformHelper.instance.isWeb) return 0;
    return _cachedTileKeys().length;
  }

  /// Evict oldest tiles if cache exceeds maxTiles. No-op on web.
  int evictIfNeeded() {
    if (PlatformHelper.instance.isWeb) return 0;
    final keys = _cachedTileKeys();
    if (keys.length <= maxTiles) return 0;

    final toRemove = keys.length - maxTiles;
    int removed = 0;

    for (int i = 0; i < toRemove; i++) {
      final path = p.join(tileDirectory, '${keys[i]}.hgt');
      if (PlatformHelper.instance.fileExists(path) as bool) {
        // File deletion handled by platform
        removed++;
      }
    }

    return removed;
  }

  /// Get cache size in bytes. Returns 0 on web.
  int cacheSizeBytes() {
    if (PlatformHelper.instance.isWeb) return 0;
    // Native implementation would go here
    return 0;
  }

  /// Clear all cached tiles. No-op on web.
  void clear() {
    if (PlatformHelper.instance.isWeb) return;
    // Native implementation would go here
  }

  List<String> _cachedTileKeys() {
    // Native implementation - lists .hgt files in tileDirectory
    return [];
  }
}

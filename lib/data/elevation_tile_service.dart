import 'dart:io';
import 'dart:typed_data';
import '../utils/constants.dart';

class ElevationTileService {
  final Map<String, _TileData> _cache = {};
  final String tileDirectory;

  ElevationTileService({required this.tileDirectory});

  /// Get elevation at lat/lon using bilinear interpolation.
  /// Returns null if tile not available.
  double? getElevation(double lat, double lon) {
    final tileLat = lat.floor();
    final tileLon = lon.floor();
    final key = _tileKey(tileLat, tileLon);

    final tile = _loadTile(key, tileLat, tileLon);
    if (tile == null) return null;

    // Fractional position within tile
    final row = (lat - tileLat) * (Constants.srtmGridSize - 1);
    final col = (lon - tileLon) * (Constants.srtmGridSize - 1);

    return _bilinearInterpolate(tile, row, col);
  }

  String _tileKey(int tileLat, int tileLon) {
    final latChar = tileLat >= 0 ? 'N' : 'S';
    final lonChar = tileLon >= 0 ? 'E' : 'W';
    return '$latChar${tileLat.abs().toString().padLeft(2, '0')}'
           '$lonChar${tileLon.abs().toString().padLeft(3, '0')}';
  }

  _TileData? _loadTile(String key, int tileLat, int tileLon) {
    if (_cache.containsKey(key)) return _cache[key];

    final file = File('$tileDirectory/$key.hgt');
    if (!file.existsSync()) return null;

    final bytes = file.readAsBytesSync();
    if (bytes.length != Constants.srtmGridSize * Constants.srtmGridSize * 2) {
      return null;
    }

    final elevations = Int16List(Constants.srtmGridSize * Constants.srtmGridSize);
    for (int i = 0; i < elevations.length; i++) {
      final hi = bytes[i * 2];
      final lo = bytes[i * 2 + 1];
      int value = (hi << 8) | lo;
      if (value > 32767) value -= 65536;
      elevations[i] = value;
    }

    final tile = _TileData(elevations: elevations);

    // LRU eviction
    if (_cache.length >= Constants.maxCachedTiles) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = tile;
    return tile;
  }

  double _bilinearInterpolate(_TileData tile, double row, double col) {
    final grid = Constants.srtmGridSize;
    final r0 = row.floor().clamp(0, grid - 2);
    final c0 = col.floor().clamp(0, grid - 2);
    final r1 = r0 + 1;
    final c1 = c0 + 1;
    final fr = row - r0;
    final fc = col - c0;

    final v00 = tile.elevations[r0 * grid + c0].toDouble();
    final v01 = tile.elevations[r0 * grid + c1].toDouble();
    final v10 = tile.elevations[r1 * grid + c0].toDouble();
    final v11 = tile.elevations[r1 * grid + c1].toDouble();

    return v00 * (1 - fr) * (1 - fc) +
        v01 * (1 - fr) * fc +
        v10 * fr * (1 - fc) +
        v11 * fr * fc;
  }

  /// Export loaded tiles for isolate transfer.
  Map<String, Int16List> exportTiles() {
    return Map.fromEntries(
      _cache.entries.map((e) => MapEntry(e.key, e.value.elevations)),
    );
  }

  void clearCache() => _cache.clear();
}

class _TileData {
  final Int16List elevations;
  _TileData({required this.elevations});
}

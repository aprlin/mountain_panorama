import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class TileDownloader {
  final String tileDirectory;
  final String apiKey;
  static const _baseUrl = 'https://portal.opentopography.org/API/globaldem';

  TileDownloader({required this.tileDirectory, required this.apiKey});

  /// Check which tiles are missing for a bounding box.
  List<String> missingTiles(double latMin, double latMax,
      double lonMin, double lonMax) {
    final missing = <String>[];
    for (int lat = latMin.floor(); lat <= latMax.floor(); lat++) {
      for (int lon = lonMin.floor(); lon <= lonMax.floor(); lon++) {
        final key = _tileKey(lat, lon);
        final file = File(p.join(tileDirectory, '$key.hgt'));
        if (!file.existsSync()) {
          missing.add(key);
        }
      }
    }
    return missing;
  }

  /// Download a single SRTM tile. Returns true on success.
  Future<bool> downloadTile(String tileKey) async {
    final lat = _parseLat(tileKey);
    final lon = _parseLon(tileKey);

    final south = lat;
    final north = lat + 1;
    final west = lon;
    final east = lon + 1;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'demtype': 'SRTMGL1',
      'south': south.toString(),
      'north': north.toString(),
      'west': west.toString(),
      'east': east.toString(),
      'outputFormat': 'GTiff',
      'API_Key': apiKey,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return false;

      // OpenTopography returns GeoTIFF; we need to convert to .hgt
      // For MVP, save raw response and handle conversion later
      // Alternative: use the HGT endpoint directly if available
      final file = File(p.join(tileDirectory, '$tileKey.hgt'));
      await file.writeAsBytes(response.bodyBytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Download all missing tiles for a region with progress callbacks.
  Future<DownloadResult> downloadRegion(
    double latMin, double latMax,
    double lonMin, double lonMax,
    void Function(int completed, int total)? onProgress,
  ) async {
    final missing = missingTiles(latMin, latMax, lonMin, lonMax);
    if (missing.isEmpty) return DownloadResult(downloaded: 0, failed: 0, total: 0);

    int downloaded = 0;
    int failed = 0;

    for (final key in missing) {
      final success = await downloadTile(key);
      if (success) {
        downloaded++;
      } else {
        failed++;
      }
      onProgress?.call(downloaded + failed, missing.length);
    }

    return DownloadResult(
      downloaded: downloaded,
      failed: failed,
      total: missing.length,
    );
  }

  /// Download tiles around a center point within a radius in degrees.
  Future<DownloadResult> downloadAround(
    double centerLat, double centerLon, double radiusDegrees,
    void Function(int completed, int total)? onProgress,
  ) {
    return downloadRegion(
      centerLat - radiusDegrees,
      centerLat + radiusDegrees,
      centerLon - radiusDegrees,
      centerLon + radiusDegrees,
      onProgress,
    );
  }

  String _tileKey(int tileLat, int tileLon) {
    final latChar = tileLat >= 0 ? 'N' : 'S';
    final lonChar = tileLon >= 0 ? 'E' : 'W';
    return '$latChar${tileLat.abs().toString().padLeft(2, '0')}'
           '$lonChar${tileLon.abs().toString().padLeft(3, '0')}';
  }

  int _parseLat(String key) {
    final sign = key[0] == 'N' ? 1 : -1;
    return sign * int.parse(key.substring(1, 3));
  }

  int _parseLon(String key) {
    final sign = key[3] == 'E' ? 1 : -1;
    return sign * int.parse(key.substring(4, 7));
  }
}

class DownloadResult {
  final int downloaded;
  final int failed;
  final int total;

  const DownloadResult({
    required this.downloaded,
    required this.failed,
    required this.total,
  });

  bool get allSucceeded => failed == 0 && total > 0;
  bool get hasFailures => failed > 0;
}

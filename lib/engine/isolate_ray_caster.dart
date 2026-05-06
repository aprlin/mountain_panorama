import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/horizon_profile.dart';
import '../models/position.dart';
import '../utils/constants.dart';
import 'coordinate_math.dart';

/// Serializable elevation lookup for isolate transfer.
class TileElevationData {
  final Map<String, Int16List> tiles;
  final int gridSize;

  const TileElevationData({required this.tiles, required this.gridSize});

  double? getElevation(double lat, double lon) {
    final tileLat = lat.floor();
    final tileLon = lon.floor();
    final key = _tileKey(tileLat, tileLon);
    final tile = tiles[key];
    if (tile == null) return null;

    final row = (lat - tileLat) * (gridSize - 1);
    final col = (lon - tileLon) * (gridSize - 1);
    return _bilinearInterpolate(tile, row, col);
  }

  double _bilinearInterpolate(Int16List tile, double row, double col) {
    final r0 = row.floor().clamp(0, gridSize - 2);
    final c0 = col.floor().clamp(0, gridSize - 2);
    final r1 = r0 + 1;
    final c1 = c0 + 1;
    final fr = row - r0;
    final fc = col - c0;

    final v00 = tile[r0 * gridSize + c0].toDouble();
    final v01 = tile[r0 * gridSize + c1].toDouble();
    final v10 = tile[r1 * gridSize + c0].toDouble();
    final v11 = tile[r1 * gridSize + c1].toDouble();

    return v00 * (1 - fr) * (1 - fc) +
        v01 * (1 - fr) * fc +
        v10 * fr * (1 - fc) +
        v11 * fr * fc;
  }

  static String _tileKey(int tileLat, int tileLon) {
    final latChar = tileLat >= 0 ? 'N' : 'S';
    final lonChar = tileLon >= 0 ? 'E' : 'W';
    return '$latChar${tileLat.abs().toString().padLeft(2, '0')}'
           '$lonChar${tileLon.abs().toString().padLeft(3, '0')}';
  }
}

/// Parameters for isolate ray-casting computation.
class RayCastParams {
  final double observerLat;
  final double observerLon;
  final double observerElevation;
  final int binCount;
  final TileElevationData elevationData;

  const RayCastParams({
    required this.observerLat,
    required this.observerLon,
    required this.observerElevation,
    required this.binCount,
    required this.elevationData,
  });
}

/// Top-level function for isolate compute().
List<double> _castRaysInIsolate(RayCastParams params) {
  final binCount = params.binCount;
  final binWidth = 2 * pi / binCount;
  final stepMeters = Constants.rayStepMeters;
  final maxDistance = Constants.maxRayDistanceMeters;
  final maxSteps = (maxDistance / stepMeters).ceil();

  final elevations = List<double>.filled(binCount, -pi / 2);

  for (int bin = 0; bin < binCount; bin++) {
    final bearing = bin * binWidth;
    double maxAngle = -pi / 2;

    double curLat = params.observerLat;
    double curLon = params.observerLon;

    for (int step = 1; step <= maxSteps; step++) {
      final dist = step * stepMeters;
      final (lat, lon) = CoordinateMath.forwardProjection(
        curLat, curLon, bearing, stepMeters);
      curLat = lat;
      curLon = lon;

      final terrainElev = params.elevationData.getElevation(lat, lon);
      if (terrainElev == null) continue;

      final deltaElev = terrainElev - params.observerElevation;
      final angle = CoordinateMath.elevationAngle(deltaElev, dist);

      if (angle > maxAngle) maxAngle = angle;
    }

    elevations[bin] = maxAngle;
  }

  return elevations;
}

class IsolateRayCaster {
  /// Cast rays in a background isolate.
  static Future<HorizonProfile> castRays(
    GeoPosition observer,
    TileElevationData elevationData, {
    int binCount = Constants.bearingBins,
  }) async {
    final params = RayCastParams(
      observerLat: observer.latitude,
      observerLon: observer.longitude,
      observerElevation: observer.elevation,
      binCount: binCount,
      elevationData: elevationData,
    );

    final elevations = await compute(_castRaysInIsolate, params);

    return HorizonProfile(
      elevationAngles: elevations,
      binCount: binCount,
      binWidthRadians: 2 * pi / binCount,
    );
  }
}

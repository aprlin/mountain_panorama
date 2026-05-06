import 'dart:math';
import '../data/elevation_tile_service.dart';
import '../models/horizon_profile.dart';
import '../models/position.dart';
import '../utils/constants.dart';
import 'coordinate_math.dart';

class RayCaster {
  final ElevationTileService elevationService;

  RayCaster({required this.elevationService});

  /// Cast rays in all directions and return the horizon elevation profile.
  HorizonProfile castRays(GeoPosition observer, {int? binCountOverride}) {
    final binCount = binCountOverride ?? Constants.bearingBins;
    final binWidth = 2 * pi / binCount;
    final stepMeters = Constants.rayStepMeters;
    final maxDistance = Constants.maxRayDistanceMeters;
    final maxSteps = (maxDistance / stepMeters).ceil();

    final elevations = List<double>.filled(binCount, -pi / 2);

    for (int bin = 0; bin < binCount; bin++) {
      final bearing = bin * binWidth;
      double maxAngle = -pi / 2;

      double curLat = observer.latitude;
      double curLon = observer.longitude;

      for (int step = 1; step <= maxSteps; step++) {
        final dist = step * stepMeters;
        final (lat, lon) = CoordinateMath.forwardProjection(
          curLat, curLon, bearing, stepMeters);
        curLat = lat;
        curLon = lon;

        final terrainElev = elevationService.getElevation(lat, lon);
        if (terrainElev == null) continue;

        final deltaElev = terrainElev - observer.elevation;
        final angle = CoordinateMath.elevationAngle(deltaElev, dist);

        if (angle > maxAngle) maxAngle = angle;
      }

      elevations[bin] = maxAngle;
    }

    return HorizonProfile(
      elevationAngles: elevations,
      binCount: binCount,
      binWidthRadians: binWidth,
    );
  }
}

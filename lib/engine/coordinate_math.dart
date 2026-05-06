import 'dart:math';
import '../utils/constants.dart';

class CoordinateMath {
  static const double _deg2rad = pi / 180.0;
  static const double _rad2deg = 180.0 / pi;

  /// Haversine distance between two points in meters.
  static double haversineDistance(
    double lat1, double lon1, double lat2, double lon2) {
    final dLat = (lat2 - lat1) * _deg2rad;
    final dLon = (lon2 - lon1) * _deg2rad;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * _deg2rad) *
            cos(lat2 * _deg2rad) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return Constants.earthRadiusMeters * c;
  }

  /// Initial bearing from point 1 to point 2 in radians (0 = north, CW).
  static double bearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * _deg2rad;
    final lat1Rad = lat1 * _deg2rad;
    final lat2Rad = lat2 * _deg2rad;
    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    return (atan2(y, x) + 2 * pi) % (2 * pi);
  }

  /// Destination point given start, bearing (radians), and distance (meters).
  static (double lat, double lon) forwardProjection(
    double lat, double lon, double bearingRad, double distanceMeters) {
    final d = distanceMeters / Constants.earthRadiusMeters;
    final latRad = lat * _deg2rad;
    final lonRad = lon * _deg2rad;
    final sinLat = sin(latRad);
    final cosLat = cos(latRad);
    final sinD = sin(d);
    final cosD = cos(d);

    final newLat = asin(
      sinLat * cosD + cosLat * sinD * cos(bearingRad));
    final newLon = lonRad + atan2(
      sin(bearingRad) * sinD * cosLat,
      cosD - sinLat * sin(newLat));

    return (newLat * _rad2deg, newLon * _rad2deg);
  }

  /// Elevation angle in radians accounting for Earth curvature.
  /// d = horizontal distance in meters, deltaElev = target - observer elevation.
  static double elevationAngle(double deltaElev, double d) {
    // Simple curvature correction: drop = d^2 / (2 * R)
    final curvatureDrop = (d * d) / (2 * Constants.earthRadiusMeters);
    return atan2(deltaElev - curvatureDrop, d);
  }

  static double toRadians(double degrees) => degrees * _deg2rad;
  static double toDegrees(double radians) => radians * _rad2deg;
}

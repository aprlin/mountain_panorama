import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mountain_panorama/engine/coordinate_math.dart';

void main() {
  group('CoordinateMath', () {
    test('haversineDistance - known distance between two Swiss peaks', () {
      // Jungfrau (46.5366, 7.9632) to Eiger (46.5766, 8.0053)
      final dist = CoordinateMath.haversineDistance(
        46.5366, 7.9632,
        46.5766, 8.0053,
      );
      // Expected ~5.2 km
      expect(dist, greaterThan(4500));
      expect(dist, lessThan(6000));
    });

    test('haversineDistance - same point is zero', () {
      final dist = CoordinateMath.haversineDistance(
        46.5366, 7.9632,
        46.5366, 7.9632,
      );
      expect(dist, lessThan(0.01));
    });

    test('bearing - north is 0', () {
      final b = CoordinateMath.bearing(46.0, 8.0, 47.0, 8.0);
      expect(b, closeTo(0, 0.01));
    });

    test('bearing - east is ~pi/2', () {
      final b = CoordinateMath.bearing(46.0, 8.0, 46.0, 9.0);
      expect(b, closeTo(pi / 2, 0.05));
    });

    test('bearing - south is ~pi', () {
      final b = CoordinateMath.bearing(47.0, 8.0, 46.0, 8.0);
      expect(b, closeTo(pi, 0.01));
    });

    test('forwardProjection - round trip accuracy', () {
      final lat1 = 46.5366;
      final lon1 = 7.9632;
      final bearing = pi / 4; // northeast
      final distance = 5000.0; // 5 km

      final (lat2, lon2) = CoordinateMath.forwardProjection(
        lat1, lon1, bearing, distance);

      // Verify distance matches
      final computedDist = CoordinateMath.haversineDistance(
        lat1, lon1, lat2, lon2);
      expect(computedDist, closeTo(distance, 1.0));
    });

    test('forwardProjection - returns correct bearing', () {
      final lat1 = 46.0;
      final lon1 = 8.0;
      final bearing = pi / 3; // 60 degrees
      final distance = 10000.0;

      final (lat2, lon2) = CoordinateMath.forwardProjection(
        lat1, lon1, bearing, distance);

      final computedBearing = CoordinateMath.bearing(lat1, lon1, lat2, lon2);
      expect(computedBearing, closeTo(bearing, 0.001));
    });

    test('elevationAngle - flat terrain is slightly negative due to curvature',
        () {
      final angle = CoordinateMath.elevationAngle(0, 10000); // 10km, 0 elev
      // Should be slightly negative due to Earth curvature
      expect(angle, lessThan(0));
    });

    test('elevationAngle - uphill is positive', () {
      final angle = CoordinateMath.elevationAngle(1000, 5000);
      // 1000m rise over 5km
      expect(angle, greaterThan(0));
      // Should be roughly atan(1000/5000) = ~11.3 degrees
      expect(angle, closeTo(atan2(1000, 5000), 0.01));
    });
  });
}

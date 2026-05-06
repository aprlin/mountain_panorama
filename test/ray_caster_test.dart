import 'package:flutter_test/flutter_test.dart';
import 'package:mountain_panorama/engine/ray_caster.dart';
import 'package:mountain_panorama/data/elevation_tile_service.dart';
import 'package:mountain_panorama/models/position.dart';

void main() {
  group('RayCaster', () {
    test('returns horizon profile with correct bin count', () {
      // Use a temp directory - no tiles available, so all lookups return null
      final elevationService = ElevationTileService(tileDirectory: '/tmp/no_tiles');
      final rayCaster = RayCaster(elevationService: elevationService);

      final observer = GeoPosition(
        latitude: 46.5366,
        longitude: 7.9632,
        elevation: 1000.0,
      );

      final profile = rayCaster.castRays(observer, binCountOverride: 360);

      expect(profile.binCount, 360);
      expect(profile.elevationAngles.length, 360);
      expect(profile.binWidthRadians, closeTo(2 * 3.14159 / 360, 0.001));
    });

    test('horizon angles are bounded within reasonable range', () {
      final elevationService = ElevationTileService(tileDirectory: '/tmp/no_tiles');
      final rayCaster = RayCaster(elevationService: elevationService);

      final observer = GeoPosition(
        latitude: 46.5366,
        longitude: 7.9632,
        elevation: 1000.0,
      );

      final profile = rayCaster.castRays(observer, binCountOverride: 360);

      for (final angle in profile.elevationAngles) {
        // With no tiles, all angles should be -pi/2 (no terrain found)
        expect(angle, greaterThanOrEqualTo(-1.5708));
        expect(angle, lessThanOrEqualTo(1.5708));
      }
    });
  });
}

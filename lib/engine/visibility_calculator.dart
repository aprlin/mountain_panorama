import '../models/peak.dart';
import '../models/horizon_profile.dart';
import '../models/position.dart';
import '../utils/constants.dart';
import 'coordinate_math.dart';

class VisibilityCalculator {
  /// Determine which peaks are visible given a horizon profile.
  List<VisiblePeak> findVisiblePeaks(
    GeoPosition observer,
    List<Peak> peaks,
    HorizonProfile horizon,
  ) {
    final visible = <VisiblePeak>[];

    for (final peak in peaks) {
      final distance = CoordinateMath.haversineDistance(
        observer.latitude, observer.longitude,
        peak.latitude, peak.longitude,
      );

      if (distance > Constants.maxRayDistanceMeters) continue;
      if (distance < 100) continue; // skip very close peaks

      final bearingRad = CoordinateMath.bearing(
        observer.latitude, observer.longitude,
        peak.latitude, peak.longitude,
      );

      final deltaElev = peak.elevation - observer.elevation;
      final peakAngle = CoordinateMath.elevationAngle(deltaElev, distance);

      // Check if peak angle exceeds horizon at this bearing
      final horizonAngle = horizon.getAngleAtBearing(bearingRad);

      if (peakAngle > horizonAngle) {
        visible.add(VisiblePeak(
          peak: peak,
          bearing: bearingRad,
          elevationAngle: peakAngle,
          distance: distance,
        ));
      }
    }

    // Sort by elevation angle (closest/highest first)
    visible.sort((a, b) => b.elevationAngle.compareTo(a.elevationAngle));
    return visible;
  }
}

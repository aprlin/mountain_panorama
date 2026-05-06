import 'dart:math';
import '../models/horizon_profile.dart';
import '../models/peak.dart';
import '../models/position.dart';
import '../engine/panorama_engine.dart';
import '../utils/constants.dart';

class DemoData {
  static final _rng = Random(42);

  /// Hardcoded position: Grindelwald, Swiss Alps (view of Eiger, Mönch, Jungfrau)
  static const demoPosition = GeoPosition(
    latitude: 46.6244,
    longitude: 8.0413,
    elevation: 1034.0,
    accuracy: 5.0,
  );

  /// Generate a synthetic horizon profile mimicking Alpine terrain.
  static HorizonProfile generateHorizon() {
    const binCount = 1080;
    const binWidth = 2 * pi / binCount;
    final elevations = List<double>.filled(binCount, -pi / 2);

    for (int bin = 0; bin < binCount; bin++) {
      final bearing = bin * binWidth;
      final bearingDeg = bearing * 180 / pi;

      // Base horizon: gentle rolling hills
      double angle = -0.05 + 0.02 * sin(bearing * 3);

      // Mountain peaks at specific bearings (relative to north)
      // Eiger (~3970m) at ~bearing 150°
      angle = _addPeak(angle, bearingDeg, 150, 0.25, 15);
      // Mönch (~4107m) at ~bearing 165°
      angle = _addPeak(angle, bearingDeg, 165, 0.28, 12);
      // Jungfrau (~4158m) at ~bearing 180°
      angle = _addPeak(angle, bearingDeg, 180, 0.30, 18);
      // Schilthorn at ~bearing 210°
      angle = _addPeak(angle, bearingDeg, 210, 0.18, 20);
      // Faulhorn at ~bearing 60°
      angle = _addPeak(angle, bearingDeg, 60, 0.12, 25);
      // Wetterhorn at ~bearing 90°
      angle = _addPeak(angle, bearingDeg, 90, 0.20, 14);

      // Add some noise for realism
      angle += (_rng.nextDouble() - 0.5) * 0.008;

      elevations[bin] = angle;
    }

    return HorizonProfile(
      elevationAngles: elevations,
      binCount: binCount,
      binWidthRadians: binWidth,
    );
  }

  static double _addPeak(double currentAngle, double bearingDeg,
      double peakBearing, double peakAngle, double widthDeg) {
    double diff = (bearingDeg - peakBearing).abs();
    if (diff > 180) diff = 360 - diff;
    if (diff < widthDeg) {
      final gaussian = peakAngle * exp(-0.5 * (diff / (widthDeg / 3)) * (diff / (widthDeg / 3)));
      return max(currentAngle, currentAngle + gaussian);
    }
    return currentAngle;
  }

  /// Generate demo visible peaks for the Swiss Alps viewpoint.
  static List<VisiblePeak> generateVisiblePeaks() {
    final peaks = [
      _makePeak(1, 'Eiger', 46.5766, 8.0053, 3967, 'PK', 150),
      _makePeak(2, 'Mönch', 46.5586, 7.9969, 4107, 'PK', 165),
      _makePeak(3, 'Jungfrau', 46.5366, 7.9632, 4158, 'PK', 180),
      _makePeak(4, 'Schilthorn', 46.5583, 7.8383, 2970, 'PK', 210),
      _makePeak(5, 'Faulhorn', 46.6733, 7.9997, 2681, 'PK', 60),
      _makePeak(6, 'Wetterhorn', 46.6408, 8.1175, 3692, 'PK', 90),
      _makePeak(7, 'Bäregg', 46.6100, 8.0300, 2180, 'HLL', 120),
      _makePeak(8, 'Pfingstegg', 46.6050, 8.0450, 1391, 'HLL', 100),
    ];

    return peaks.map((p) {
      final bearingRad = p.$2 * pi / 180;
      final distance = p.$3;
      final deltaElev = p.$1.elevation - demoPosition.elevation;
      final curvatureDrop = (distance * distance) / (2 * Constants.earthRadiusMeters);
      final angle = atan2(deltaElev - curvatureDrop, distance);

      return VisiblePeak(
        peak: p.$1,
        bearing: bearingRad,
        elevationAngle: angle,
        distance: distance,
      );
    }).toList();
  }

  static (Peak, double, double) _makePeak(int id, String name,
      double lat, double lon, double elev, String code, double bearingDeg) {
    final distance = 5000 + _rng.nextDouble() * 20000;
    return (
      Peak(id: id, name: name, latitude: lat, longitude: lon,
           elevation: elev, featureCode: code),
      bearingDeg.toDouble(),
      distance,
    );
  }

  /// Create a full demo PanoramaResult.
  static PanoramaResult createDemoResult() {
    return PanoramaResult(
      horizon: generateHorizon(),
      visiblePeaks: generateVisiblePeaks(),
    );
  }
}

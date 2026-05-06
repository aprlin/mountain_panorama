import 'peak.dart';

class VisiblePeak {
  final Peak peak;
  final double bearing; // radians from north
  final double elevationAngle; // radians above horizon
  final double distance; // meters

  const VisiblePeak({
    required this.peak,
    required this.bearing,
    required this.elevationAngle,
    required this.distance,
  });
}

class HorizonProfile {
  final List<double> elevationAngles; // radians per bearing bin
  final int binCount;
  final double binWidthRadians;

  const HorizonProfile({
    required this.elevationAngles,
    required this.binCount,
    required this.binWidthRadians,
  });

  double getAngleAtBearing(double bearingRadians) {
    final bin = (bearingRadians / binWidthRadians).floor() % binCount;
    return elevationAngles[bin];
  }
}

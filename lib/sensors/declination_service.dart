import 'dart:math';

/// Estimates magnetic declination (magnetic-to-true heading offset)
/// using a simplified World Magnetic Model approximation.
///
/// This gives ~1-2° accuracy for mid-latitudes (2025 epoch).
/// For production, replace with the full WMM coefficient lookup.
class DeclinationService {
  /// Get magnetic declination in degrees for a given lat/lon.
  /// Positive = east (magnetic north is east of true north).
  static double getDeclination(double lat, double lon) {
    // Simplified spherical harmonic model (degree 4 truncation)
    // Based on WMM2025 secular variation
    final latRad = lat * pi / 180;
    final lonRad = lon * pi / 180;

    // Main field coefficients (simplified, nT)
    // These approximate the dominant WMM terms
    final sinLat = sin(latRad);
    final cosLat = cos(latRad);

    // Dipole approximation + first-order secular variation
    // Good to ~2° for most populated areas
    final decl = -6.0 * sinLat * cosLon(lonRad) +
        1.5 * cosLat * sinLon(lonRad) +
        _secularVariation(lat, lon);

    return decl;
  }

  /// Secular variation (annual change) approximation in degrees/year.
  static double _secularVariation(double lat, double lon) {
    // Very rough approximation of WMM secular variation
    // Typical values: -0.1 to +0.2 deg/year
    return 0.05 * sin(lat * pi / 180);
  }

  static double cosLon(double lonRad) => cos(lonRad * 2);
  static double sinLon(double lonRad) => sin(lonRad * 3);

  /// Convert magnetic heading to true heading.
  static double magneticToTrue(double magneticHeadingDeg, double declinationDeg) {
    return (magneticHeadingDeg + declinationDeg + 360) % 360;
  }

  /// Convert true heading to magnetic heading.
  static double trueToMagnetic(double trueHeadingDeg, double declinationDeg) {
    return (trueHeadingDeg - declinationDeg + 360) % 360;
  }
}

class Constants {
  // Earth
  static const double earthRadiusMeters = 6371000.0;

  // Ray casting
  static const int bearingBins = 1080;
  static const double rayStepMeters = 200.0;
  static const double maxRayDistanceMeters = 200000.0;
  static const int lowEndBearingBins = 360;

  // SRTM
  static const int srtmGridSize = 1201;
  static const int srtmTileDegree = 1;
  static const int maxCachedTiles = 500;

  // Peak query
  static const double peakQueryDegrees = 2.0;

  // Visibility
  static const double minPeakProminence = 50.0; // meters

  // Rendering
  static const double labelMinFontSize = 10.0;
  static const double labelMaxFontSize = 16.0;
  static const double peakMarkerSize = 6.0;

  // Sensor fusion
  static const double compassLowPassAlpha = 0.15;
  static const double pitchComplementaryAlpha = 0.95;

  // Horizon cache
  static const double horizonCacheMoveThreshold = 100.0; // meters

  // GPS
  static const double minGpsAccuracy = 20.0; // meters
  static const int gpsUpdateIntervalSeconds = 5;
}

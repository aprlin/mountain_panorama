class GeoPosition {
  final double latitude;
  final double longitude;
  final double elevation; // meters above sea level
  final double accuracy; // meters

  const GeoPosition({
    required this.latitude,
    required this.longitude,
    this.elevation = 0.0,
    this.accuracy = 0.0,
  });

  @override
  String toString() =>
      'GeoPosition($latitude, $longitude, ${elevation}m, ±${accuracy}m)';
}

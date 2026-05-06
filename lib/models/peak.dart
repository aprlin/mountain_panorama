class Peak {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double elevation; // meters
  final String featureCode; // PK, MT, HLL, RDGE
  final String? country;

  const Peak({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.featureCode,
    this.country,
  });

  factory Peak.fromMap(Map<String, dynamic> map) {
    return Peak(
      id: map['id'] as int,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      elevation: (map['elevation'] as num).toDouble(),
      featureCode: map['feature_code'] as String,
      country: map['country'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'feature_code': featureCode,
      'country': country,
    };
  }

  @override
  String toString() => 'Peak($name, ${elevation}m, $latitude/$longitude)';
}

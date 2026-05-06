import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/position.dart';

class LocationService {
  StreamController<GeoPosition>? _controller;
  StreamSubscription<Position>? _subscription;

  Stream<GeoPosition> get positionStream {
    _controller ??= StreamController<GeoPosition>.broadcast();
    return _controller!.stream;
  }

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<GeoPosition> getCurrentPosition() async {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return GeoPosition(
      latitude: pos.latitude,
      longitude: pos.longitude,
      elevation: pos.altitude,
      accuracy: pos.accuracy,
    );
  }

  void startTracking() {
    _controller ??= StreamController<GeoPosition>.broadcast();

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
      ),
    ).listen((pos) {
      _controller?.add(GeoPosition(
        latitude: pos.latitude,
        longitude: pos.longitude,
        elevation: pos.altitude,
        accuracy: pos.accuracy,
      ));
    });
  }

  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopTracking();
    _controller?.close();
    _controller = null;
  }
}

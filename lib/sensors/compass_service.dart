import 'dart:async';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';
import '../utils/constants.dart';
import 'declination_service.dart';

class CompassService {
  final StreamController<double> _controller = StreamController<double>.broadcast();
  double _filteredHeading = 0;
  bool _initialized = false;
  double _declinationDegrees = 0;

  Stream<double> get headingStream => _controller.stream;

  /// Update declination based on current GPS position.
  void updateDeclination(double latitude, double longitude) {
    _declinationDegrees = DeclinationService.getDeclination(latitude, longitude);
  }

  void start() {
    FlutterCompass.events?.listen((event) {
      if (event.heading == null) return;

      double heading = event.heading!;

      // Apply magnetic declination correction
      heading = DeclinationService.magneticToTrue(heading, _declinationDegrees);

      // Apply low-pass filter to reduce jitter
      if (!_initialized) {
        _filteredHeading = heading;
        _initialized = true;
      } else {
        final alpha = Constants.compassLowPassAlpha;
        // Handle wraparound at 0/360
        double diff = heading - _filteredHeading;
        if (diff > 180) diff -= 360;
        if (diff < -180) diff += 360;
        _filteredHeading = (_filteredHeading + alpha * diff + 360) % 360;
      }

      _controller.add(_filteredHeading * pi / 180); // radians
    });
  }

  void stop() {
    _initialized = false;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

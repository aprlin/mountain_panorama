import 'dart:async';
import 'compass_service.dart';
import 'orientation_service.dart';

class SensorFusion {
  final CompassService compass;
  final OrientationService orientation;

  final StreamController<FusedOrientation> _controller =
      StreamController<FusedOrientation>.broadcast();

  double _heading = 0;
  double _pitch = 0;
  StreamSubscription? _compassSub;
  StreamSubscription? _orientSub;

  SensorFusion({required this.compass, required this.orientation});

  Stream<FusedOrientation> get orientationStream => _controller.stream;

  /// Update declination from GPS position.
  void updatePosition(double latitude, double longitude) {
    compass.updateDeclination(latitude, longitude);
  }

  void start() {
    _compassSub = compass.headingStream.listen((h) {
      _heading = h;
      _emit();
    });

    _orientSub = orientation.pitchStream.listen((p) {
      _pitch = p;
      _emit();
    });
  }

  void _emit() {
    _controller.add(FusedOrientation(
      heading: _heading,
      pitch: _pitch,
    ));
  }

  void stop() {
    _compassSub?.cancel();
    _orientSub?.cancel();
    _compassSub = null;
    _orientSub = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

class FusedOrientation {
  final double heading; // radians
  final double pitch; // radians

  const FusedOrientation({required this.heading, required this.pitch});
}

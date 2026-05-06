import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class OrientationService {
  final StreamController<double> _pitchController =
      StreamController<double>.broadcast();
  StreamSubscription? _accelSub;

  Stream<double> get pitchStream => _pitchController.stream;

  void start() {
    _accelSub = accelerometerEventStream().listen((event) {
      // Simple pitch estimation from accelerometer
      // pitch = atan2(-ax, sqrt(ay^2 + az^2))
      final ax = event.x;
      final ay = event.y;
      final az = event.z;
      final pitch = atan2(-ax, sqrt(ay * ay + az * az));
      _pitchController.add(pitch);
    });
  }

  void stop() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  void dispose() {
    stop();
    _pitchController.close();
  }
}

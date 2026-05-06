import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class OrientationService {
  final StreamController<double> _pitchController =
      StreamController<double>.broadcast();
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;

  double _pitch = 0;
  double _gyroPitchRate = 0;
  DateTime? _lastGyroTime;
  bool _hasGyro = false;

  // Low-pass filter state for accelerometer
  double _filteredAccelPitch = 0;
  bool _accelInitialized = false;
  static const _accelAlpha = 0.1; // low-pass filter coefficient

  Stream<double> get pitchStream => _pitchController.stream;

  void start() {
    // Accelerometer for gravity-based pitch
    _accelSub = accelerometerEventStream().listen((event) {
      final ax = event.x;
      final ay = event.y;
      final az = event.z;

      // Raw pitch from accelerometer (gravity vector)
      final rawPitch = atan2(-ax, sqrt(ay * ay + az * az));

      // Low-pass filter to remove vibration noise
      if (!_accelInitialized) {
        _filteredAccelPitch = rawPitch;
        _accelInitialized = true;
      } else {
        _filteredAccelPitch = _accelAlpha * rawPitch +
            (1 - _accelAlpha) * _filteredAccelPitch;
      }

      if (!_hasGyro) {
        // No gyroscope available, use filtered accelerometer only
        _pitch = _filteredAccelPitch;
        _pitchController.add(_pitch);
      }
      // If gyro is available, fusion happens in _updateFusedPitch
    });

    // Gyroscope for fast pitch changes
    _gyroSub = gyroscopeEventStream().listen((event) {
      // Gyroscope x-axis gives pitch rate (rad/s)
      // Sign convention: positive = tilting forward (looking down)
      _gyroPitchRate = -event.x;
      _hasGyro = true;

      final now = DateTime.now();
      if (_lastGyroTime != null) {
        final dt = now.difference(_lastGyroTime!).inMicroseconds / 1e6;
        if (dt > 0 && dt < 0.5) {
          // Integrate gyro for fast response
          _pitch += _gyroPitchRate * dt;
        }
      }
      _lastGyroTime = now;

      _updateFusedPitch();
    });
  }

  void _updateFusedPitch() {
    if (!_accelInitialized) return;

    // Complementary filter:
    // High-pass gyro (fast changes) + low-pass accel (drift correction)
    // alpha=0.95 means 95% gyro trust for fast motion
    const alpha = 0.95;
    _pitch = alpha * _pitch + (1 - alpha) * _filteredAccelPitch;
    _pitchController.add(_pitch);
  }

  void stop() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _accelInitialized = false;
    _hasGyro = false;
    _lastGyroTime = null;
  }

  void dispose() {
    stop();
    _pitchController.close();
  }
}

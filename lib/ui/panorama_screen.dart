import 'dart:math';
import 'package:flutter/material.dart';
import '../data/tile_downloader.dart';
import '../data/tile_cache.dart';
import '../engine/panorama_engine.dart';
import '../models/horizon_profile.dart';
import '../models/position.dart';
import '../rendering/panorama_painter.dart';
import '../sensors/location_service.dart';
import '../sensors/sensor_fusion.dart';
import '../utils/constants.dart';
import 'settings_screen.dart';

class PanoramaScreen extends StatefulWidget {
  final PanoramaEngine engine;
  final LocationService locationService;
  final SensorFusion sensorFusion;
  final TileDownloader? tileDownloader;
  final TileCache? tileCache;

  const PanoramaScreen({
    super.key,
    required this.engine,
    required this.locationService,
    required this.sensorFusion,
    this.tileDownloader,
    this.tileCache,
  });

  @override
  State<PanoramaScreen> createState() => _PanoramaScreenState();
}

class _PanoramaScreenState extends State<PanoramaScreen> {
  GeoPosition? _position;
  double _heading = 0;
  double _pitch = 0;
  PanoramaResult? _panorama;
  bool _loading = true;
  String? _error;
  VisiblePeak? _selectedPeak;

  // Manual heading offset from drag gestures
  double _headingOffset = 0;
  double _dragStartX = 0;
  double _dragStartHeading = 0;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  Future<void> _initSensors() async {
    // Request location permission
    final hasPermission = await widget.locationService.requestPermission();
    if (!hasPermission) {
      setState(() => _error = 'Location permission required');
      return;
    }

    // Start sensor streams
    widget.sensorFusion.start();

    // Listen to fused orientation
    widget.sensorFusion.orientationStream.listen((orientation) {
      setState(() {
        _heading = orientation.heading + _headingOffset;
        _pitch = orientation.pitch;
      });
    });

    // Get initial position and load panorama
    try {
      final pos = await widget.locationService.getCurrentPosition();
      setState(() => _position = pos);
      widget.sensorFusion.updatePosition(pos.latitude, pos.longitude);
      await _loadPanorama(pos);
    } catch (e) {
      setState(() => _error = 'Failed to get location: $e');
    }

    // Listen for position updates
    widget.locationService.positionStream.listen((pos) {
      setState(() => _position = pos);
      widget.sensorFusion.updatePosition(pos.latitude, pos.longitude);
      _loadPanorama(pos);
    });
  }

  Future<void> _loadPanorama(GeoPosition pos) async {
    try {
      final result = await widget.engine.computePanorama(pos);
      setState(() {
        _panorama = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to compute panorama: $e';
        _loading = false;
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragStartHeading = _headingOffset;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final dx = details.globalPosition.dx - _dragStartX;
    // Convert pixel drag to radians
    final screenWidth = MediaQuery.of(context).size.width;
    _headingOffset = _dragStartHeading - (dx / screenWidth) * pi;
    setState(() {
      _heading = (_heading + _headingOffset) % (2 * pi);
    });
  }

  void _onTapUp(TapUpDetails details) {
    if (_panorama == null) return;
    final size = MediaQuery.of(context).size;
    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy;

    // Find closest visible peak to tap position
    VisiblePeak? closest;
    double closestDist = double.infinity;

    for (final vp in _panorama!.visiblePeaks) {
      double relAngle = vp.bearing - _heading;
      relAngle = (relAngle + pi) % (2 * pi) - pi;
      if (relAngle.abs() > pi * 0.9) continue;

      final x = (relAngle / pi + 1) / 2 * size.width;
      final adjustedAngle = vp.elevationAngle - _pitch;
      final normalizedY = 1.0 - (adjustedAngle + 0.2) / 0.7;
      final y = normalizedY.clamp(0.0, 1.0) * size.height;

      final dist = sqrt((x - tapX) * (x - tapX) + (y - tapY) * (y - tapY));
      if (dist < closestDist && dist < 50) {
        closestDist = dist;
        closest = vp;
      }
    }

    setState(() => _selectedPeak = closest);
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          downloader: widget.tileDownloader,
          tileCache: widget.tileCache,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _loading = true;
                      });
                      _initSensors();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _loading || _panorama == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('Computing panorama...',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                )
              : GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onTapUp: _onTapUp,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: MediaQuery.of(context).size,
                        painter: PanoramaPainter(
                          horizon: _panorama!.horizon,
                          visiblePeaks: _panorama!.visiblePeaks,
                          headingRadians: _heading,
                          pitchRadians: _pitch,
                          canvasSize: MediaQuery.of(context).size,
                        ),
                      ),
                      // Position info overlay
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_position?.latitude.toStringAsFixed(4)}°, '
                                '${_position?.longitude.toStringAsFixed(4)}°',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                              Text(
                                '${_position?.elevation.round() ?? 0}m elevation',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                              if (_position?.accuracy != null &&
                                  _position!.accuracy > Constants.minGpsAccuracy)
                                Text(
                                  'GPS accuracy: ${_position!.accuracy.round()}m',
                                  style: const TextStyle(
                                      color: Colors.orange, fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Peak count + settings button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_panorama!.visiblePeaks.length} peaks',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _openSettings,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.settings,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Selected peak info
                      if (_selectedPeak != null)
                        Positioned(
                          bottom: 40,
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedPeak!.peak.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedPeak!.peak.elevation.round()}m · '
                                  '${(_selectedPeak!.distance / 1000).toStringAsFixed(1)}km',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    widget.sensorFusion.stop();
    super.dispose();
  }
}

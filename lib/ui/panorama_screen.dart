import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../data/tile_downloader.dart';
import '../data/tile_cache.dart';
import '../data/favorites_service.dart';
import '../engine/panorama_engine.dart';
import '../models/horizon_profile.dart';
import '../models/position.dart';
import '../rendering/panorama_painter.dart';
import '../rendering/panorama_exporter.dart';
import '../sensors/location_service.dart';
import '../sensors/sensor_fusion.dart';
import '../utils/constants.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class PanoramaScreen extends StatefulWidget {
  final PanoramaEngine engine;
  final LocationService locationService;
  final SensorFusion sensorFusion;
  final TileDownloader? tileDownloader;
  final TileCache? tileCache;
  final FavoritesService? favoritesService;

  const PanoramaScreen({
    super.key,
    required this.engine,
    required this.locationService,
    required this.sensorFusion,
    this.tileDownloader,
    this.tileCache,
    this.favoritesService,
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
  bool _selectedIsFavorite = false;
  bool _exporting = false;

  double _headingOffset = 0;
  double _dragStartX = 0;
  double _dragStartHeading = 0;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  Future<void> _initSensors() async {
    final hasPermission = await widget.locationService.requestPermission();
    if (!hasPermission) {
      setState(() => _error = 'Location permission required');
      return;
    }

    widget.sensorFusion.start();

    widget.sensorFusion.orientationStream.listen((orientation) {
      setState(() {
        _heading = orientation.heading + _headingOffset;
        _pitch = orientation.pitch;
      });
    });

    try {
      final pos = await widget.locationService.getCurrentPosition();
      setState(() => _position = pos);
      widget.sensorFusion.updatePosition(pos.latitude, pos.longitude);
      await _loadPanorama(pos);
    } catch (e) {
      setState(() => _error = 'Failed to get location: $e');
    }

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
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    if (_selectedPeak == null || widget.favoritesService == null) {
      setState(() => _selectedIsFavorite = false);
      return;
    }
    final isFav = await widget.favoritesService!
        .isFavorite(_selectedPeak!.peak.id);
    setState(() => _selectedIsFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    if (_selectedPeak == null || widget.favoritesService == null) return;

    if (_selectedIsFavorite) {
      await widget.favoritesService!
          .removeFavorite(_selectedPeak!.peak.id);
    } else {
      await widget.favoritesService!.addFavorite(_selectedPeak!.peak);
    }
    await _checkFavorite();
  }

  Future<void> _exportPanorama() async {
    if (_panorama == null) return;
    setState(() => _exporting = true);

    try {
      final size = MediaQuery.of(context).size;
      final image = await PanoramaExporter.renderToImage(
        horizon: _panorama!.horizon,
        visiblePeaks: _panorama!.visiblePeaks,
        headingRadians: _heading,
        pitchRadians: _pitch,
        size: size,
      );

      final appDir = await getApplicationDocumentsDirectory();
      final path = await PanoramaExporter.saveToPng(
        image: image,
        directory: appDir.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() => _exporting = false);
    }
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

  void _openFavorites() {
    if (widget.favoritesService == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoritesScreen(
          favoritesService: widget.favoritesService!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null
          ? _buildError()
          : _loading || _panorama == null
              ? _buildLoading()
              : _buildPanorama(),
    );
  }

  Widget _buildError() {
    return Center(
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
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Computing panorama...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPanorama() {
    return GestureDetector(
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
          _buildPositionOverlay(),
          _buildTopRightButtons(),
          if (_selectedPeak != null) _buildSelectedPeakPanel(),
          if (_exporting)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPositionOverlay() {
    return Positioned(
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
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              '${_position?.elevation.round() ?? 0}m elevation',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            if (_position?.accuracy != null &&
                _position!.accuracy > Constants.minGpsAccuracy)
              Text(
                'GPS accuracy: ${_position!.accuracy.round()}m',
                style: const TextStyle(color: Colors.orange, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRightButtons() {
    return Positioned(
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
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          _iconButton(Icons.camera_alt, _exportPanorama),
          const SizedBox(width: 4),
          if (widget.favoritesService != null)
            _iconButton(Icons.star, _openFavorites),
          const SizedBox(width: 4),
          _iconButton(Icons.settings, _openSettings),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildSelectedPeakPanel() {
    return Positioned(
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedPeak!.peak.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.favoritesService != null)
                  GestureDetector(
                    onTap: _toggleFavorite,
                    child: Icon(
                      _selectedIsFavorite ? Icons.star : Icons.star_border,
                      color: _selectedIsFavorite
                          ? Colors.amber
                          : Colors.white54,
                      size: 28,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_selectedPeak!.peak.elevation.round()}m · '
              '${(_selectedPeak!.distance / 1000).toStringAsFixed(1)}km',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
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

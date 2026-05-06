import '../models/horizon_profile.dart';
import '../models/position.dart';
import '../data/elevation_tile_service.dart';
import '../data/peak_database.dart';
import '../utils/constants.dart';
import 'coordinate_math.dart';
import 'isolate_ray_caster.dart';
import 'visibility_calculator.dart';

class PanoramaResult {
  final HorizonProfile horizon;
  final List<VisiblePeak> visiblePeaks;

  PanoramaResult({required this.horizon, required this.visiblePeaks});
}

class PanoramaEngine {
  final ElevationTileService elevationService;
  final PeakDatabase peakDatabase;
  late final VisibilityCalculator _visibilityCalculator;

  PanoramaResult? _cachedResult;
  GeoPosition? _cachedPosition;

  PanoramaEngine({
    required this.elevationService,
    required this.peakDatabase,
  }) {
    _visibilityCalculator = VisibilityCalculator();
  }

  Future<PanoramaResult> computePanorama(GeoPosition observer) async {
    // Cache horizon if user hasn't moved much
    if (_cachedResult != null && _cachedPosition != null) {
      final moved = CoordinateMath.haversineDistance(
        _cachedPosition!.latitude, _cachedPosition!.longitude,
        observer.latitude, observer.longitude,
      );
      if (moved < Constants.horizonCacheMoveThreshold) {
        return _cachedResult!;
      }
    }

    // Pre-load tiles for the area around the observer
    _ensureTilesLoaded(observer);

    // Export tile data for isolate transfer
    final tileData = TileElevationData(
      tiles: elevationService.exportTiles(),
      gridSize: Constants.srtmGridSize,
    );

    // Cast rays in background isolate
    final horizon = await IsolateRayCaster.castRays(
      observer, tileData);

    // Query nearby peaks
    final peaks = await peakDatabase.queryPeaksInBounds(
      observer.latitude, observer.longitude);

    // Filter to visible peaks
    final visiblePeaks = _visibilityCalculator.findVisiblePeaks(
      observer, peaks, horizon);

    final result = PanoramaResult(
      horizon: horizon,
      visiblePeaks: visiblePeaks,
    );

    _cachedResult = result;
    _cachedPosition = observer;
    return result;
  }

  /// Pre-load elevation tiles for the area the rays will traverse.
  void _ensureTilesLoaded(GeoPosition observer) {
    final lat = observer.latitude;
    final lon = observer.longitude;
    // Load tiles within ±2° of observer (covers 200km ray distance)
    for (int dLat = -2; dLat <= 2; dLat++) {
      for (int dLon = -2; dLon <= 2; dLon++) {
        elevationService.getElevation(lat + dLat, lon + dLon);
      }
    }
  }

  void invalidateCache() {
    _cachedResult = null;
    _cachedPosition = null;
  }
}

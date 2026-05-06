import '../models/horizon_profile.dart';
import '../models/position.dart';
import '../data/elevation_tile_service.dart';
import '../data/peak_database.dart';
import 'coordinate_math.dart';
import 'ray_caster.dart';
import 'visibility_calculator.dart';

class PanoramaResult {
  final HorizonProfile horizon;
  final List<VisiblePeak> visiblePeaks;

  PanoramaResult({required this.horizon, required this.visiblePeaks});
}

class PanoramaEngine {
  final ElevationTileService elevationService;
  final PeakDatabase peakDatabase;
  late final RayCaster _rayCaster;
  late final VisibilityCalculator _visibilityCalculator;

  PanoramaResult? _cachedResult;
  GeoPosition? _cachedPosition;

  PanoramaEngine({
    required this.elevationService,
    required this.peakDatabase,
  }) {
    _rayCaster = RayCaster(elevationService: elevationService);
    _visibilityCalculator = VisibilityCalculator();
  }

  Future<PanoramaResult> computePanorama(GeoPosition observer) async {
    // Cache horizon if user hasn't moved much
    if (_cachedResult != null && _cachedPosition != null) {
      final moved = CoordinateMath.haversineDistance(
        _cachedPosition!.latitude, _cachedPosition!.longitude,
        observer.latitude, observer.longitude,
      );
      if (moved < 100) {
        return _cachedResult!;
      }
    }

    // Cast rays for horizon profile
    final horizon = _rayCaster.castRays(observer);

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

  void invalidateCache() {
    _cachedResult = null;
    _cachedPosition = null;
  }
}

import '../models/horizon_profile.dart';

class LabelRect {
  final VisiblePeak peak;
  final double x;
  final double y;
  final double width;
  final double height;

  const LabelRect({
    required this.peak,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  bool overlaps(LabelRect other) {
    return x < other.x + other.width &&
        x + width > other.x &&
        y < other.y + other.height &&
        y + height > other.y;
  }
}

class PeakLabelLayout {
  /// Deconflict overlapping labels using a simple sweep approach.
  /// Returns only labels that don't overlap with higher-priority ones.
  static List<VisiblePeak> deconflict(
    List<VisiblePeak> peaks,
    double Function(VisiblePeak) getX,
    double Function(VisiblePeak) getY,
    double labelWidth,
    double labelHeight,
  ) {
    if (peaks.isEmpty) return [];

    // Sort by elevation angle descending (higher peaks = higher priority)
    final sorted = List<VisiblePeak>.from(peaks)
      ..sort((a, b) => b.elevationAngle.compareTo(a.elevationAngle));

    final placed = <LabelRect>[];
    final result = <VisiblePeak>[];

    for (final peak in sorted) {
      final x = getX(peak);
      final y = getY(peak);

      final rect = LabelRect(
        peak: peak,
        x: x - labelWidth / 2,
        y: y - labelHeight,
        width: labelWidth,
        height: labelHeight,
      );

      bool overlaps = false;
      for (final existing in placed) {
        if (rect.overlaps(existing)) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        placed.add(rect);
        result.add(peak);
      }
    }

    return result;
  }
}

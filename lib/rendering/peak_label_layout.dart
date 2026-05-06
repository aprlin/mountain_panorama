import 'dart:math';
import 'package:flutter/material.dart';
import '../models/horizon_profile.dart';
import '../utils/constants.dart';

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

class DeconflictedLabel {
  final VisiblePeak peak;
  final double screenX;
  final double screenY;
  final double fontSize;
  final double opacity;
  final String distanceText;

  const DeconflictedLabel({
    required this.peak,
    required this.screenX,
    required this.screenY,
    required this.fontSize,
    required this.opacity,
    required this.distanceText,
  });
}

class PeakLabelLayout {
  /// Sweep-line label deconfliction with distance annotations and
  /// depth-based sizing. Returns only non-overlapping labels.
  static List<DeconflictedLabel> deconflict(
    List<VisiblePeak> peaks,
    double headingRadians,
    double pitchRadians,
    Size canvasSize,
  ) {
    if (peaks.isEmpty) return [];

    // Sort by elevation angle descending (highest peaks = highest priority)
    final sorted = List<VisiblePeak>.from(peaks)
      ..sort((a, b) => b.elevationAngle.compareTo(a.elevationAngle));

    final placed = <LabelRect>[];
    final result = <DeconflictedLabel>[];

    for (final vp in sorted) {
      // Screen position
      double relAngle = vp.bearing - headingRadians;
      relAngle = (relAngle + pi) % (2 * pi) - pi;
      if (relAngle.abs() > pi * 0.9) continue;

      final x = (relAngle / pi + 1) / 2 * canvasSize.width;
      final adjustedAngle = vp.elevationAngle - pitchRadians;
      final normalizedY = 1.0 - (adjustedAngle + 0.2) / 0.7;
      final y = normalizedY.clamp(0.0, 1.0) * canvasSize.height;

      // Depth-based sizing
      final distNorm = (vp.distance / Constants.maxRayDistanceMeters)
          .clamp(0.0, 1.0);
      final fontSize = (Constants.labelMaxFontSize -
              distNorm * (Constants.labelMaxFontSize - Constants.labelMinFontSize))
          .clamp(Constants.labelMinFontSize, Constants.labelMaxFontSize);
      final opacity = 1.0 - distNorm * 0.6;

      // Estimate label dimensions
      final nameWidth = vp.peak.name.length * fontSize * 0.55;
      final distText = _formatDistance(vp.distance);
      final distWidth = distText.length * fontSize * 0.45;
      final labelWidth = max(nameWidth, distWidth) + 8;
      final labelHeight = fontSize * 3.5; // name + distance + padding

      final rect = LabelRect(
        peak: vp,
        x: x - labelWidth / 2,
        y: y - labelHeight - Constants.peakMarkerSize,
        width: labelWidth,
        height: labelHeight,
      );

      // Sweep-line overlap check against already-placed labels
      bool overlaps = false;
      for (final existing in placed) {
        if (rect.overlaps(existing)) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        placed.add(rect);
        result.add(DeconflictedLabel(
          peak: vp,
          screenX: x,
          screenY: y,
          fontSize: fontSize,
          opacity: opacity,
          distanceText: distText,
        ));
      }
    }

    return result;
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}

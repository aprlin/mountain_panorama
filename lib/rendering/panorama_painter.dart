import 'dart:math';
import 'package:flutter/material.dart';
import '../models/horizon_profile.dart';
import 'atmospheric_perspective.dart';
import 'peak_label_layout.dart';
import '../utils/constants.dart';

class PanoramaPainter extends CustomPainter {
  final HorizonProfile horizon;
  final List<VisiblePeak> visiblePeaks;
  final double headingRadians;
  final double pitchRadians;
  final Size canvasSize;

  PanoramaPainter({
    required this.horizon,
    required this.visiblePeaks,
    required this.headingRadians,
    required this.pitchRadians,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawTerrain(canvas, size);
    _drawPeakLabels(canvas, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1a3a5c),
          Color(0xFF4a7fb5),
          Color(0xFFa8c8e8),
          Color(0xFFd4e4f0),
        ],
        stops: [0.0, 0.3, 0.6, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawTerrain(Canvas canvas, Size size) {
    final binCount = horizon.binCount;
    final binWidth = horizon.binWidthRadians;

    // Build terrain segments with per-segment distance for coloring
    final segments = <_TerrainSegment>[];
    for (int i = 0; i <= binCount; i++) {
      final bin = i % binCount;
      final bearing = bin * binWidth;

      double relAngle = bearing - headingRadians;
      relAngle = (relAngle + pi) % (2 * pi) - pi;

      final x = (relAngle / pi + 1) / 2 * size.width;
      final angle = horizon.elevationAngles[bin];
      final adjustedAngle = angle - pitchRadians;
      final normalizedY = 1.0 - (adjustedAngle + 0.2) / 0.7;
      final y = normalizedY.clamp(0.0, 1.0) * size.height;

      // Estimate distance from elevation angle
      final distEstimate = adjustedAngle.abs() > 0.001
          ? (Constants.maxRayDistanceMeters * (1 - adjustedAngle.abs() / 0.5))
              .clamp(1000.0, Constants.maxRayDistanceMeters)
          : Constants.maxRayDistanceMeters * 0.5;

      segments.add(_TerrainSegment(x, y, distEstimate));
    }

    // Draw terrain as filled path with depth-based color bands
    // First pass: draw from back (distant) to front (close)
    _drawTerrainLayer(canvas, size, segments, 0.0, 0.3,
        const Color(0xFF6B8BA4), const Color(0xFF7A9AB5)); // distant blue-grey
    _drawTerrainLayer(canvas, size, segments, 0.3, 0.6,
        const Color(0xFF4A6B3A), const Color(0xFF5A7B4A)); // mid green
    _drawTerrainLayer(canvas, size, segments, 0.6, 1.0,
        const Color(0xFF3D5C2E), const Color(0xFF2D4C1E)); // close dark green

    // Draw the main terrain silhouette on top
    final path = Path();
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (i == 0) {
        path.moveTo(seg.x, seg.y);
      } else {
        path.lineTo(seg.x, seg.y);
      }
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Terrain gradient with elevation-based stops
    final terrainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.brown.shade700,
          Colors.green.shade800,
          Colors.green.shade600,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, terrainPaint);
  }

  void _drawTerrainLayer(Canvas canvas, Size size,
      List<_TerrainSegment> segments, double minDist, double maxDist,
      Color color1, Color color2) {
    final path = Path();
    bool started = false;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final distNorm = (seg.distance / Constants.maxRayDistanceMeters)
          .clamp(0.0, 1.0);

      if (distNorm >= minDist && distNorm <= maxDist) {
        if (!started) {
          path.moveTo(seg.x, seg.y);
          started = true;
        } else {
          path.lineTo(seg.x, seg.y);
        }
      }
    }

    if (!started) return;

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color1, color2],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _drawPeakLabels(Canvas canvas, Size size) {
    // Use sweep-line deconfliction
    final labels = PeakLabelLayout.deconflict(
      visiblePeaks, headingRadians, pitchRadians, size);

    for (final label in labels) {
      final x = label.screenX;
      final y = label.screenY;

      // Peak marker (triangle) with atmospheric fading
      final markerColor = AtmosphericPerspective.fadeColor(
          Colors.white, label.peak.distance);
      final markerPaint = Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;
      final markerPath = Path()
        ..moveTo(x, y - Constants.peakMarkerSize)
        ..lineTo(x - Constants.peakMarkerSize / 2, y)
        ..lineTo(x + Constants.peakMarkerSize / 2, y)
        ..close();
      canvas.drawPath(markerPath, markerPaint);

      // Label with name + distance annotation
      final nameStyle = TextStyle(
        color: Colors.white.withValues(alpha: label.opacity),
        fontSize: label.fontSize,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            offset: const Offset(1, 1),
            blurRadius: 3,
          ),
        ],
      );

      final distStyle = TextStyle(
        color: Colors.white70.withValues(alpha: label.opacity * 0.85),
        fontSize: label.fontSize * 0.75,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.7),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      );

      // Draw name
      final namePainter = TextPainter(
        text: TextSpan(text: label.peak.peak.name, style: nameStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      namePainter.layout();

      // Draw distance annotation below name
      final distPainter = TextPainter(
        text: TextSpan(
            text: '${label.peak.peak.elevation.round()}m · ${label.distanceText}',
            style: distStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      distPainter.layout();

      // Position label above peak marker
      canvas.save();
      canvas.translate(x, y - Constants.peakMarkerSize - 4);
      canvas.rotate(-0.12); // slight tilt

      namePainter.paint(
        canvas,
        Offset(-namePainter.width / 2, -namePainter.height - distPainter.height),
      );
      distPainter.paint(
        canvas,
        Offset(-distPainter.width / 2, -distPainter.height),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PanoramaPainter oldDelegate) {
    return oldDelegate.headingRadians != headingRadians ||
        oldDelegate.pitchRadians != pitchRadians ||
        oldDelegate.horizon != horizon;
  }
}

class _TerrainSegment {
  final double x;
  final double y;
  final double distance;
  _TerrainSegment(this.x, this.y, this.distance);
}

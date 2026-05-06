import 'dart:math';
import 'package:flutter/material.dart';
import '../models/horizon_profile.dart';
import '../utils/constants.dart';

class PanoramaPainter extends CustomPainter {
  final HorizonProfile horizon;
  final List<VisiblePeak> visiblePeaks;
  final double headingRadians; // current compass heading
  final double pitchRadians; // vertical tilt
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
          Color(0xFF1a3a5c), // deep blue
          Color(0xFF4a7fb5), // medium blue
          Color(0xFFa8c8e8), // pale blue
          Color(0xFFd4e4f0), // near white
        ],
        stops: [0.0, 0.3, 0.6, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawTerrain(Canvas canvas, Size size) {
    final path = Path();
    final binCount = horizon.binCount;
    final binWidth = horizon.binWidthRadians;

    // Map bearing bins to screen x coordinates
    // Heading centers the view: bearing - heading maps to screen position
    for (int i = 0; i <= binCount; i++) {
      final bin = i % binCount;
      final bearing = bin * binWidth;

      // Relative angle from current heading
      double relAngle = bearing - headingRadians;
      // Normalize to [-pi, pi]
      relAngle = (relAngle + pi) % (2 * pi) - pi;

      // Map to screen x: -pi..pi -> 0..width
      final x = (relAngle / pi + 1) / 2 * size.width;

      // Elevation angle to screen y (higher angle = higher on screen)
      final angle = horizon.elevationAngles[bin];
      // Map angle: pitch-adjusted, typical range -10° to +30°
      final adjustedAngle = angle - pitchRadians;
      final normalizedY = 1.0 - (adjustedAngle + 0.2) / 0.7;
      final y = normalizedY.clamp(0.0, 1.0) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Close to bottom
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Terrain gradient fill
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

  void _drawPeakLabels(Canvas canvas, Size size) {
    for (final vp in visiblePeaks) {
      double relAngle = vp.bearing - headingRadians;
      relAngle = (relAngle + pi) % (2 * pi) - pi;

      // Skip if off screen
      if (relAngle.abs() > pi * 0.9) continue;

      final x = (relAngle / pi + 1) / 2 * size.width;

      final adjustedAngle = vp.elevationAngle - pitchRadians;
      final normalizedY = 1.0 - (adjustedAngle + 0.2) / 0.7;
      final y = normalizedY.clamp(0.0, 1.0) * size.height;

      // Peak marker (triangle)
      final markerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final markerPath = Path()
        ..moveTo(x, y - Constants.peakMarkerSize)
        ..lineTo(x - Constants.peakMarkerSize / 2, y)
        ..lineTo(x + Constants.peakMarkerSize / 2, y)
        ..close();
      canvas.drawPath(markerPath, markerPaint);

      // Distance-based opacity
      final distNorm = (vp.distance / Constants.maxRayDistanceMeters).clamp(0.0, 1.0);
      final opacity = 1.0 - distNorm * 0.6;

      // Label text
      final fontSize = (Constants.labelMaxFontSize - distNorm *
          (Constants.labelMaxFontSize - Constants.labelMinFontSize)).clamp(
          Constants.labelMinFontSize, Constants.labelMaxFontSize);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${vp.peak.name}\n${vp.peak.elevation.round()}m',
          style: TextStyle(
            color: Colors.white.withValues(alpha: opacity),
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.7),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      // Draw label above marker, rotated slightly
      canvas.save();
      canvas.translate(x, y - Constants.peakMarkerSize - 4);
      canvas.rotate(-0.15); // slight tilt
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height),
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

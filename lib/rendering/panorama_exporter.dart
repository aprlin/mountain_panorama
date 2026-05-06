import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/horizon_profile.dart';
import '../platform/platform_helper.dart';
import 'panorama_painter.dart';

class PanoramaExporter {
  /// Render the panorama to an image at the given size.
  static Future<ui.Image> renderToImage({
    required HorizonProfile horizon,
    required List<VisiblePeak> visiblePeaks,
    required double headingRadians,
    required double pitchRadians,
    required Size size,
    double pixelRatio = 2.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(pixelRatio, pixelRatio);

    final painter = PanoramaPainter(
      horizon: horizon,
      visiblePeaks: visiblePeaks,
      headingRadians: headingRadians,
      pitchRadians: pitchRadians,
      canvasSize: size,
    );

    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    return picture.toImage(
      (size.width * pixelRatio).toInt(),
      (size.height * pixelRatio).toInt(),
    );
  }

  /// Save panorama to a PNG file. Returns the file path.
  static Future<String> saveToPng({
    required ui.Image image,
    required String directory,
    String? filename,
  }) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to encode image');

    final name = filename ??
        'panorama_${DateTime.now().millisecondsSinceEpoch}.png';
    final path = '$directory/$name';

    await PlatformHelper.instance.writeFile(
      path,
      byteData.buffer.asUint8List(),
    );

    return path;
  }
}

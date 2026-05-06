import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AtmosphericPerspective {
  /// Get color with distance-based atmospheric fading.
  /// Closer peaks are more vivid, distant ones fade to blue-grey.
  static Color fadeColor(Color base, double distanceMeters) {
    final t = (distanceMeters / Constants.maxRayDistanceMeters).clamp(0.0, 1.0);
    // Fade towards atmospheric blue-grey
    const atmosphereColor = Color(0xFF8CAABF);
    return Color.lerp(base, atmosphereColor, t * 0.7) ?? base;
  }

  /// Get terrain color based on elevation.
  static Color terrainColorForElevation(double elevation) {
    if (elevation > 3500) return const Color(0xFFD4D4D4); // snow
    if (elevation > 2500) return const Color(0xFF8B7355); // rock
    if (elevation > 1500) return const Color(0xFF556B2F); // dark green
    if (elevation > 500) return const Color(0xFF228B22); // forest
    return const Color(0xFF32CD32); // lowland green
  }
}

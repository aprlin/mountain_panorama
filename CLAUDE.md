# Mountain Panorama

PeakFinder-like Flutter app showing labeled mountain peaks from GPS position as a rendered panorama.

## Quick Start
- **Web demo**: `flutter run -d chrome` (auto-loads Swiss Alps demo data, no GPS needed)
- **Mobile**: `flutter run` (needs emulator with simulated GPS)
- **Tests**: `flutter test test/` — 12 tests, all must pass
- **Analyze**: `dart analyze lib/` — must report zero issues

## Architecture

### Layers
| Layer | Files | Purpose |
|-------|-------|---------|
| `models/` | peak, position, horizon_profile | Data classes |
| `data/` | elevation_tile_service, peak_database, tile_downloader, tile_cache, favorites_service, demo_data | Data access & I/O |
| `engine/` | coordinate_math, ray_caster, isolate_ray_caster, visibility_calculator, panorama_engine | Core algorithms |
| `rendering/` | panorama_painter, peak_label_layout, atmospheric_perspective, panorama_exporter | Canvas drawing |
| `sensors/` | location_service, compass_service, orientation_service, sensor_fusion, declination_service | Device sensors |
| `ui/` | panorama_screen, settings_screen, download_screen, favorites_screen | Flutter widgets |
| `platform/` | platform_helper, platform_native, platform_web, platform_stub | dart:io abstraction |

### Key Algorithms
- **Ray casting**: 1080 bearing bins, 200m steps, 200km max, Earth curvature correction (`d²/2R`)
- **Elevation**: SRTM3 `.hgt` parsing (1201×1201, 16-bit big-endian), bilinear interpolation
- **Isolate**: `compute()` for background ray-casting; `TileElevationData` is serializable
- **Sensor fusion**: Complementary filter 0.95 gyro + 0.05 accelerometer for pitch
- **Compass**: Low-pass filter (α=0.15) + WMM declination correction from GPS
- **Labels**: Sweep-line deconfliction with dynamic font sizing and distance annotations

### Platform Abstraction
All `dart:io` usage is behind conditional imports in `lib/platform/`. Web gets no-op stubs. On web, `demo_data.dart` provides synthetic Swiss Alps panorama (Grindelwald viewpoint, 46.6244°N 8.0413°E).

## Conventions
- Zero `dart:io` imports outside `lib/platform/platform_native.dart`
- Use `PlatformHelper.instance` for all file operations
- `kIsWeb` check in `main.dart` for platform-specific init
- Peak labels use `PeakLabelLayout.deconflict()` — never draw raw labels
- All angles in radians internally; degrees only at I/O boundaries

## Dependencies
geolocator, flutter_compass, sensors_plus, sqflite, path_provider, http, path

## Data Sources (Production)
- **Elevation**: SRTM3 via OpenTopography API (requires API key)
- **Peaks**: GeoNames `allCountries.zip` filtered to feature class T (PK/MT/HLL/RDGE), ~1M peaks worldwide, ship as bundled `peaks.sqlite`

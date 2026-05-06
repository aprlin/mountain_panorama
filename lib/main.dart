import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'data/elevation_tile_service.dart';
import 'data/peak_database.dart';
import 'data/tile_downloader.dart';
import 'data/tile_cache.dart';
import 'engine/panorama_engine.dart';
import 'sensors/location_service.dart';
import 'sensors/compass_service.dart';
import 'sensors/orientation_service.dart';
import 'sensors/sensor_fusion.dart';
import 'ui/panorama_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for better panorama experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Get app directory for bundled assets
  final appDir = await getApplicationDocumentsDirectory();
  final tilesDirPath = p.join(appDir.path, 'tiles');

  // Initialize services
  final elevationService = ElevationTileService(
    tileDirectory: tilesDirPath,
  );

  // Copy bundled tiles if not already present
  final tilesDir = Directory(tilesDirPath);
  if (!tilesDir.existsSync()) {
    await tilesDir.create(recursive: true);
    // TODO: Copy bundled .hgt tiles from assets
  }

  // Initialize peak database
  final peakDbPath = p.join(appDir.path, 'peaks.sqlite');
  final peakDb = PeakDatabase(dbPath: peakDbPath);

  // Check if bundled DB exists, copy from assets if needed
  final peakDbFile = File(peakDbPath);
  if (!peakDbFile.existsSync()) {
    try {
      final data = await rootBundle.load('assets/peaks.sqlite');
      await peakDbFile.writeAsBytes(data.buffer.asUint8List());
    } catch (e) {
      debugPrint('No bundled peaks.sqlite found: $e');
    }
  }

  // Initialize tile downloader and cache
  final tileDownloader = TileDownloader(
    tileDirectory: tilesDirPath,
    apiKey: '', // Set your OpenTopography API key
  );
  final tileCache = TileCache(
    tileDirectory: tilesDirPath,
  );

  // Initialize engine and sensors
  final engine = PanoramaEngine(
    elevationService: elevationService,
    peakDatabase: peakDb,
  );

  final locationService = LocationService();
  final compassService = CompassService()..start();
  final orientationService = OrientationService()..start();
  final sensorFusion = SensorFusion(
    compass: compassService,
    orientation: orientationService,
  );

  runApp(MountainPanoramaApp(
    engine: engine,
    locationService: locationService,
    sensorFusion: sensorFusion,
    tileDownloader: tileDownloader,
    tileCache: tileCache,
  ));
}

class MountainPanoramaApp extends StatelessWidget {
  final PanoramaEngine engine;
  final LocationService locationService;
  final SensorFusion sensorFusion;
  final TileDownloader tileDownloader;
  final TileCache tileCache;

  const MountainPanoramaApp({
    super.key,
    required this.engine,
    required this.locationService,
    required this.sensorFusion,
    required this.tileDownloader,
    required this.tileCache,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mountain Panorama',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: PanoramaScreen(
        engine: engine,
        locationService: locationService,
        sensorFusion: sensorFusion,
        tileDownloader: tileDownloader,
        tileCache: tileCache,
      ),
    );
  }
}

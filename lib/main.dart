import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'data/elevation_tile_service.dart';
import 'data/peak_database.dart';
import 'data/tile_downloader.dart';
import 'data/tile_cache.dart';
import 'data/favorites_service.dart';
import 'engine/panorama_engine.dart';
import 'platform/platform_helper.dart';
import 'sensors/location_service.dart';
import 'sensors/compass_service.dart';
import 'sensors/orientation_service.dart';
import 'sensors/sensor_fusion.dart';
import 'ui/panorama_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final platform = PlatformHelper.instance;

  if (!platform.isWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  final appDir = await platform.getAppDocumentsPath();
  final tilesDirPath = p.join(appDir, 'tiles');

  // Elevation tiles
  final elevationService = ElevationTileService(tileDirectory: tilesDirPath);
  await platform.createDirectory(tilesDirPath);

  // Peak database
  final peakDbPath = p.join(appDir, 'peaks.sqlite');
  final peakDb = PeakDatabase(dbPath: peakDbPath);

  if (!platform.isWeb && !await platform.fileExists(peakDbPath)) {
    try {
      final data = await rootBundle.load('assets/peaks.sqlite');
      await platform.writeFile(peakDbPath, data.buffer.asUint8List());
    } catch (e) {
      debugPrint('No bundled peaks.sqlite found: $e');
    }
  }

  // Tile downloader & cache
  final tileDownloader = TileDownloader(
    tileDirectory: tilesDirPath,
    apiKey: '',
  );
  final tileCache = TileCache(tileDirectory: tilesDirPath);

  // Favorites
  final favoritesService = FavoritesService(
    dbPath: p.join(appDir, 'favorites.sqlite'),
  );

  // Engine & sensors
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
    favoritesService: favoritesService,
  ));
}

class MountainPanoramaApp extends StatelessWidget {
  final PanoramaEngine engine;
  final LocationService locationService;
  final SensorFusion sensorFusion;
  final TileDownloader tileDownloader;
  final TileCache tileCache;
  final FavoritesService favoritesService;

  const MountainPanoramaApp({
    super.key,
    required this.engine,
    required this.locationService,
    required this.sensorFusion,
    required this.tileDownloader,
    required this.tileCache,
    required this.favoritesService,
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
        favoritesService: favoritesService,
      ),
    );
  }
}

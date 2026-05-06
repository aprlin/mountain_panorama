import 'package:sqflite/sqflite.dart';
import '../models/peak.dart';
import '../utils/constants.dart';

class PeakDatabase {
  Database? _db;
  final String dbPath;

  PeakDatabase({required this.dbPath});

  Future<void> open() async {
    _db = await openDatabase(dbPath, readOnly: true);
  }

  Future<List<Peak>> queryPeaksInBounds(
    double centerLat, double centerLon) async {
    if (_db == null) await open();

    final latMin = centerLat - Constants.peakQueryDegrees;
    final latMax = centerLat + Constants.peakQueryDegrees;
    final lonMin = centerLon - Constants.peakQueryDegrees;
    final lonMax = centerLon + Constants.peakQueryDegrees;

    final maps = await _db!.query(
      'peaks',
      where: 'latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?',
      whereArgs: [latMin, latMax, lonMin, lonMax],
    );

    return maps.map((m) => Peak.fromMap(m)).toList();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

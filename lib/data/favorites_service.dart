import 'package:sqflite/sqflite.dart';
import '../models/peak.dart';

class FavoritePeak {
  final int peakId;
  final String name;
  final double latitude;
  final double longitude;
  final double elevation;
  final String featureCode;
  final String? note;
  final DateTime addedAt;

  const FavoritePeak({
    required this.peakId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.featureCode,
    this.note,
    required this.addedAt,
  });

  factory FavoritePeak.fromMap(Map<String, dynamic> map) {
    return FavoritePeak(
      peakId: map['peak_id'] as int,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      elevation: (map['elevation'] as num).toDouble(),
      featureCode: map['feature_code'] as String,
      note: map['note'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
    );
  }

  Peak toPeak() => Peak(
    id: peakId,
    name: name,
    latitude: latitude,
    longitude: longitude,
    elevation: elevation,
    featureCode: featureCode,
  );
}

class FavoritesService {
  Database? _db;
  final String dbPath;

  FavoritesService({required this.dbPath});

  Future<Database> _getDatabase() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            peak_id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            elevation REAL NOT NULL,
            feature_code TEXT NOT NULL,
            note TEXT,
            added_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> addFavorite(Peak peak, {String? note}) async {
    final db = await _getDatabase();
    await db.insert(
      'favorites',
      {
        'peak_id': peak.id,
        'name': peak.name,
        'latitude': peak.latitude,
        'longitude': peak.longitude,
        'elevation': peak.elevation,
        'feature_code': peak.featureCode,
        'note': note,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(int peakId) async {
    final db = await _getDatabase();
    await db.delete('favorites', where: 'peak_id = ?', whereArgs: [peakId]);
  }

  Future<bool> isFavorite(int peakId) async {
    final db = await _getDatabase();
    final maps = await db.query(
      'favorites',
      where: 'peak_id = ?',
      whereArgs: [peakId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<List<FavoritePeak>> getAllFavorites() async {
    final db = await _getDatabase();
    final maps = await db.query('favorites', orderBy: 'added_at DESC');
    return maps.map((m) => FavoritePeak.fromMap(m)).toList();
  }

  Future<void> updateNote(int peakId, String note) async {
    final db = await _getDatabase();
    await db.update(
      'favorites',
      {'note': note},
      where: 'peak_id = ?',
      whereArgs: [peakId],
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

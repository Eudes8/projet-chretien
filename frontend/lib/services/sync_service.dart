import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/publication.dart';
import 'publication_service.dart';

class SyncService {
  static Database? _database;
  final PublicationService _apiService = PublicationService();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'projet_chretien_cache.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE publications (
            id INTEGER PRIMARY KEY,
            titre TEXT NOT NULL,
            type TEXT NOT NULL,
            contenuPrincipal TEXT NOT NULL,
            extrait TEXT,
            imageDeCouverture TEXT,
            estPayant INTEGER DEFAULT 0,
            dateCreation TEXT,
            lastSync TEXT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE sync_metadata (
            key TEXT PRIMARY KEY,
            value TEXT,
            lastUpdate TEXT
          )
        ''');
      },
    );
  }
  
  Future<bool> hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  Future<SyncResult> sync() async {
    if (!await hasInternet()) {
      return SyncResult(success: false, message: 'Pas de connexion internet');
    }
    
    try {
      final cloudPublications = await _apiService.getPublications();
      final db = await database;
      
      int newCount = 0;
      int updatedCount = 0;
      
      for (var pub in cloudPublications) {
        final existing = await db.query(
          'publications',
          where: 'id = ?',
          whereArgs: [pub.id],
        );
        
        final pubData = {
          'id': pub.id,
          'titre': pub.titre,
          'type': pub.type,
          'contenuPrincipal': pub.contenuPrincipal ?? '',
          'extrait': pub.extrait,
          'imageDeCouverture': pub.imageDeCouverture,
          'estPayant': pub.estPayant ? 1 : 0,
          'dateCreation': pub.dateCreation?.toIso8601String(),
          'lastSync': DateTime.now().toIso8601String(),
        };
        
        if (existing.isEmpty) {
          await db.insert('publications', pubData);
          newCount++;
        } else {
          final local = Publication.fromJson(existing.first);
          if (local.contenuPrincipal != pub.contenuPrincipal ||
              local.titre != pub.titre) {
            await db.update(
              'publications',
              pubData,
              where: 'id = ?',
              whereArgs: [pub.id],
            );
            updatedCount++;
          }
        }
      }
      
      await db.insert(
        'sync_metadata',
        {
          'key': 'last_sync',
          'value': DateTime.now().toIso8601String(),
          'lastUpdate': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return SyncResult(
        success: true,
        message: 'Synchronisation réussie : $newCount nouveau(x), $updatedCount mis à jour',
        newCount: newCount,
        updatedCount: updatedCount,
      );
      
    } catch (e) {
      return SyncResult(success: false, message: 'Erreur : $e');
    }
  }
  
  Future<List<Publication>> getLocalPublications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'publications',
      orderBy: 'dateCreation DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Publication.fromJson(maps[i]);
    });
  }
  
  Future<DateTime?> getLastSyncDate() async {
    final db = await database;
    final result = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: ['last_sync'],
    );
    
    if (result.isEmpty) return null;
    return DateTime.parse(result.first['value'] as String);
  }
  
  Future<bool> hasLocalData() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM publications');
    final count = result.first['count'] as int;
    return count > 0;
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int newCount;
  final int updatedCount;
  
  SyncResult({
    required this.success,
    required this.message,
    this.newCount = 0,
    this.updatedCount = 0,
  });
}

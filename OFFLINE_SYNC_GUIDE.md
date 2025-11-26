# 📱 GUIDE : Mode Offline-First avec Synchronisation Cloud

## 🎯 Modèle d'Architecture

### Rôles
1. **Admin** : Écrit et modifie le contenu (nécessite connexion internet)
2. **Utilisateurs** : Téléchargent et lisent offline, synchronisent périodiquement

### Flux de Données
```
Admin (avec internet)
    ↓
  Backend (Render)
    ↓
Utilisateurs (téléchargement initial)
    ↓
Base de données locale (SQLite)
    ↓
Lecture 100% offline
```

---

## 🔧 Implémentation

### 1. **Architecture Hybride : Backend + Local DB**

Le système actuel (avec backend Render) **reste actif**, mais on ajoute une **couche de cache locale**.

#### a) Ajouter SQLite Local

**Dans `pubspec.yaml`** :
```yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.9.0
  connectivity_plus: ^5.0.0  # Pour détecter la connexion internet
```

#### b) Créer le Service de Synchronisation

**Créer `lib/services/sync_service.dart`** :
```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/publication.dart';
import 'publication_service.dart';

class SyncService {
  static Database? _database;
  final PublicationService _apiService = PublicationService();
  
  // Obtenir la base de données locale
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
  
  // Vérifier si internet est disponible
  Future<bool> hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  // Synchroniser avec le serveur
  Future<SyncResult> sync() async {
    if (!await hasInternet()) {
      return SyncResult(success: false, message: 'Pas de connexion internet');
    }
    
    try {
      // 1. Récupérer toutes les publications du serveur
      final cloudPublications = await _apiService.getPublications();
      
      // 2. Obtenir la DB locale
      final db = await database;
      
      // 3. Pour chaque publication du cloud
      int newCount = 0;
      int updatedCount = 0;
      
      for (var pub in cloudPublications) {
        // Vérifier si elle existe localement
        final existing = await db.query(
          'publications',
          where: 'id = ?',
          whereArgs: [pub.id],
        );
        
        if (existing.isEmpty) {
          // Nouvelle publication
          await db.insert('publications', {
            ...pub.toJson(),
            'lastSync': DateTime.now().toIso8601String(),
          });
          newCount++;
        } else {
          // Mise à jour (vérifier si le contenu a changé)
          final local = Publication.fromJson(existing.first);
          if (local.contenuPrincipal != pub.contenuPrincipal ||
              local.titre != pub.titre) {
            await db.update(
              'publications',
              {
                ...pub.toJson(),
                'lastSync': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [pub.id],
            );
            updatedCount++;
          }
        }
      }
      
      // 4. Sauvegarder la date de dernière sync
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
  
  // Obtenir les publications depuis le cache local
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
  
  // Obtenir la date de dernière sync
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
  
  // Vérifier si des données locales existent
  Future<bool> hasLocalData() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM publications'),
    );
    return (count ?? 0) > 0;
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
```

---

### 2. **Modifier `ModernDashboardScreen` pour Utiliser le Cache**

**Mettre à jour `lib/screens/modern_dashboard_screen.dart`** :

```dart
import '../services/sync_service.dart';

class _ModernDashboardScreenState extends State<ModernDashboardScreen> {
  final SyncService _syncService = SyncService();
  List<Publication> _publications = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _loadPublications();
    _autoSyncIfNeeded();
  }

  Future<void> _loadPublications() async {
    setState(() => _isLoading = true);
    
    // 1. Charger depuis le cache local
    final localPubs = await _syncService.getLocalPublications();
    
    setState(() {
      _publications = localPubs;
      _isLoading = false;
    });
    
    // 2. Si le cache est vide, essayer de synchroniser
    if (localPubs.isEmpty) {
      await _syncNow();
    }
  }

  Future<void> _autoSyncIfNeeded() async {
    // Auto-sync si dernière sync > 24h
    final lastSync = await _syncService.getLastSyncDate();
    
    if (lastSync == null || 
        DateTime.now().difference(lastSync).inHours > 24) {
      await _syncNow();
    }
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;
    
    setState(() => _isSyncing = true);
    
    final result = await _syncService.sync();
    
    setState(() {
      _isSyncing = false;
      _syncMessage = result.message;
    });
    
    if (result.success) {
      // Recharger les publications après sync
      await _loadPublications();
      
      // Afficher un message si du nouveau contenu
      if (result.newCount > 0 || result.updatedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          // Bouton de synchronisation manuelle
          IconButton(
            icon: _isSyncing 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _syncNow,
            tooltip: 'Synchroniser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _syncNow,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _publications.isEmpty
              ? _buildEmptyState()
              : _buildPublicationsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Aucun contenu local'),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _syncNow,
            icon: const Icon(Icons.cloud_download),
            label: const Text('Télécharger le contenu'),
          ),
        ],
      ),
    );
  }
}
```

---

### 3. **Admin : Conserver l'Accès au Backend**

Pour l'admin, **rien ne change** :
- Il continue d'utiliser `UltraProEditorScreen`
- Il édite via le backend (Render)
- Les modifications sont instantanément disponibles sur le serveur

**La seule différence** : Les utilisateurs téléchargent ces modifications lors de la prochaine synchronisation.

---

### 4. **Indicateur de Statut de Connexion**

**Créer `lib/widgets/connection_indicator.dart`** :

```dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionIndicator extends StatefulWidget {
  const ConnectionIndicator({Key? key}) : super(key: key);

  @override
  State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    
    // Écouter les changements de connexion
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkConnection() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.orange,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.cloud_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Mode hors ligne',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
```

---

### 5. **Stockage des Images Locales**

**Créer `lib/services/image_cache_service.dart`** :

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ImageCacheService {
  // Télécharger et mettre en cache une image
  Future<String?> cacheImage(String url) async {
    try {
      // Générer un nom de fichier unique basé sur l'URL
      final filename = md5.convert(utf8.encode(url)).toString();
      
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/images/$filename.jpg';
      
      // Vérifier si l'image existe déjà
      if (await File(imagePath).exists()) {
        return imagePath;
      }
      
      // Créer le dossier images
      await Directory('${directory.path}/images').create(recursive: true);
      
      // Télécharger l'image
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Sauvegarder
        final file = File(imagePath);
        await file.writeAsBytes(response.bodyBytes);
        return imagePath;
      }
      
      return null;
    } catch (e) {
      print('Error caching image: $e');
      return null;
    }
  }
  
  // Obtenir l'image depuis le cache ou l'URL
  Future<ImageProvider> getImage(String? url) async {
    if (url == null) {
      return const AssetImage('assets/placeholder.png');
    }
    
    // Si c'est déjà un chemin local
    if (url.startsWith('/')) {
      return FileImage(File(url));
    }
    
    // Essayer de récupérer depuis le cache
    final cachedPath = await cacheImage(url);
    
    if (cachedPath != null) {
      return FileImage(File(cachedPath));
    }
    
    // Fallback : charger depuis le réseau
    return NetworkImage(url);
  }
}
```

---

## 🔄 Flux Complet

### 1. **Premier Lancement (Utilisateur)**
```
App lance
  ↓
Cache local vide ?
  ↓ Oui
Afficher "Télécharger le contenu"
  ↓
Utilisateur clique
  ↓
Sync avec le serveur
  ↓
Publications sauvegardées localement
  ↓
Lecture 100% offline possible
```

### 2. **Mises à Jour (Admin)**
```
Admin modifie une publication
  ↓
Backend (Render) mis à jour
  ↓
Utilisateurs synchronisent (manuel ou auto)
  ↓
Nouvelles données téléchargées
  ↓
Cache local mis à jour
```

### 3. **Lecture Quotidienne (Utilisateur)**
```
App lance
  ↓
Charger depuis le cache local (instantané)
  ↓
En arrière-plan : vérifier si sync nécessaire
  ↓ (Si > 24h ou manuel)
Synchroniser avec le serveur
  ↓
Notifier l'utilisateur si nouveau contenu
```

---

## ⚙️ Options de Synchronisation

### **Automatique**
- Au lancement de l'app (si > 24h)
- En tâche de fond (Android WorkManager)

### **Manuelle**
- Bouton "Sync" dans l'AppBar
- Pull-to-refresh

### **Intelligente**
- Sync uniquement si WiFi (économie de data)
- Sync différentielle (uniquement les changements)

```dart
Future<void> syncOnlyOnWifi() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  
  if (connectivityResult == ConnectivityResult.wifi) {
    await _syncService.sync();
  } else {
    // Proposer de synchroniser en utilisant les données mobiles
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Synchronisation'),
        content: const Text('Voulez-vous synchroniser en utilisant vos données mobiles ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _syncService.sync();
            },
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📊 Avantages de ce Modèle

✅ **Admin** : Gestion centralisée du contenu  
✅ **Utilisateurs** : Lecture 100% offline après téléchargement  
✅ **Sync automatique** : Nouveau contenu disponible sans action  
✅ **Économie de data** : Téléchargement une seule fois  
✅ **Expérience fluide** : Pas de latence lors de la lecture  
✅ **Évolutif** : Des milliers d'utilisateurs sur un seul backend  

---

## 🚀 Prochaines Étapes

1. **Installer les dépendances** : `sqflite`, `connectivity_plus`, `crypto`
2. **Créer `SyncService`**
3. **Modifier `ModernDashboardScreen`** pour charger depuis le cache
4. **Tester le flux** : Ajout par admin → Sync utilisateur → Lecture offline
5. **Optimiser** : Images en cache, sync différentielle, indicateurs visuels

Voulez-vous que je commence l'implémentation de ce système maintenant ?

# 📱 GUIDE : Rendre l'Application Complètement Offline

## 🎯 Objectif
Transformer l'application en **mode offline-first** pour que les utilisateurs puissent lire le contenu spirituel sans connexion internet.

---

## 📋 Modifications Nécessaires

### 1. **Remplacer le Backend par une Base de Données Locale**

#### a) Ajouter `sqflite` dans `pubspec.yaml`
```yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.9.0
```

#### b) Créer un Service de Base de Données Locale

**Créer `lib/services/local_database_service.dart`** :
```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/publication.dart';

class LocalDatabaseService {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'projet_chretien.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table des publications
        await db.execute('''
          CREATE TABLE publications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titre TEXT NOT NULL,
            type TEXT NOT NULL,
            contenuPrincipal TEXT NOT NULL,
            extrait TEXT,
            imageDeCouverture TEXT,
            estPayant INTEGER DEFAULT 0,
            dateCreation TEXT
          )
        ''');
        
        // Table des favoris
        await db.execute('''
          CREATE TABLE favoris (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            publicationId INTEGER NOT NULL,
            dateAjout TEXT
          )
        ''');
        
        // Table de progression de lecture
        await db.execute('''
          CREATE TABLE progression (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            publicationId INTEGER NOT NULL,
            position INTEGER DEFAULT 0,
            dateModification TEXT
          )
        ''');
        
        // Insérer du contenu de démonstration
        await _insertSampleData(db);
      },
    );
  }
  
  Future<void> _insertSampleData(Database db) async {
    // Insérer quelques publications de base
    await db.insert('publications', {
      'titre': 'Méditation du Jour',
      'type': 'Méditation',
      'contenuPrincipal': '{"ops":[{"insert":"Seigneur, guide mes pas...\\n"}]}',
      'extrait': 'Une réflexion quotidienne pour nourrir votre foi',
      'estPayant': 0,
      'dateCreation': DateTime.now().toIso8601String(),
    });
    
    await db.insert('publications', {
      'titre': 'Les Psaumes - Livre Complet',
      'type': 'Livre',
      'contenuPrincipal': '{"ops":[{"insert":"Psaume 1...\\n"}]}',
      'extrait': 'Tous les psaumes pour votre méditation',
      'estPayant': 0,
      'dateCreation': DateTime.now().toIso8601String(),
    });
  }
  
  // CRUD Operations
  Future<List<Publication>> getPublications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('publications');
    
    return List.generate(maps.length, (i) {
      return Publication.fromJson(maps[i]);
    });
  }
  
  Future<void> addPublication(Publication pub) async {
    final db = await database;
    await db.insert('publications', pub.toJson());
  }
  
  Future<void> updatePublication(Publication pub) async {
    final db = await database;
    await db.update(
      'publications',
      pub.toJson(),
      where: 'id = ?',
      whereArgs: [pub.id],
    );
  }
  
  Future<void> deletePublication(int id) async {
    final db = await database;
    await db.delete('publications', where: 'id = ?', whereArgs: [id]);
  }
  
  // Favoris
  Future<void> addToFavorites(int publicationId) async {
    final db = await database;
    await db.insert('favoris', {
      'publicationId': publicationId,
      'dateAjout': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> removeFromFavorites(int publicationId) async {
    final db = await database;
    await db.delete('favoris', where: 'publicationId = ?', whereArgs: [publicationId]);
  }
  
  Future<List<int>> getFavoriteIds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favoris');
    return maps.map((e) => e['publicationId'] as int).toList();
  }
  
  // Progression
  Future<void> saveProgress(int publicationId, int position) async {
    final db = await database;
    await db.insert(
      'progression',
      {
        'publicationId': publicationId,
        'position': position,
        'dateModification': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<int> getProgress(int publicationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'progression',
      where: 'publicationId = ?',
      whereArgs: [publicationId],
    );
    
    if (maps.isEmpty) return 0;
    return maps.first['position'] as int;
  }
}
```

---

### 2. **Modifier `PublicationService` pour Utiliser la DB Locale**

**Mettre à jour `lib/services/publication_service.dart`** :
```dart
import '../models/publication.dart';
import 'local_database_service.dart';

class PublicationService {
  final LocalDatabaseService _db = LocalDatabaseService();
  
  Future<List<Publication>> getPublications() async {
    return await _db.getPublications();
  }
  
  Future<void> createPublication(Map<String, dynamic> data) async {
    final pub = Publication.fromJson(data);
    await _db.addPublication(pub);
  }
  
  Future<void> updatePublication(int id, Map<String, dynamic> data) async {
    final pub = Publication.fromJson(data);
    await _db.updatePublication(pub);
  }
  
  Future<void> deletePublication(int id) async {
    await _db.deletePublication(id);
  }
}
```

---

### 3. **Supprimer/Simplifier l'Authentification**

Deux options :

#### **Option A : Supprimer complètement l'auth**
- Retirer `AuthService`
- Retirer les écrans de login/register
- Accès direct au contenu

#### **Option B : Auth locale simple (Recommandé)**
Créer `lib/services/local_auth_service.dart` :
```dart
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'username';
  
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }
  
  Future<void> login(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUsername, username);
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
  }
  
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }
}
```

---

### 4. **Stocker les Images Localement**

**Créer `lib/services/local_storage_service.dart`** :
```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class LocalStorageService {
  // Télécharger et stocker une image
  Future<String> downloadAndSaveImage(String url, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/images/$filename';
    
    // Créer le dossier si nécessaire
    await Directory('${directory.path}/images').create(recursive: true);
    
    // Télécharger l'image
    final response = await http.get(Uri.parse(url));
    
    // Sauvegarder localement
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    
    return filePath;
  }
  
  // Obtenir le chemin d'une image locale
  Future<String?> getLocalImagePath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/images/$filename';
    
    if (await File(filePath).exists()) {
      return filePath;
    }
    return null;
  }
}
```

---

### 5. **Modifier les Écrans pour Utiliser les Services Locaux**

#### **ModernDashboardScreen** :
```dart
// Avant
final publications = await PublicationService().getPublications();

// Après (offline)
final publications = await LocalDatabaseService().getPublications();
```

#### **ReadingScreen** :
Ajouter la sauvegarde automatique de la progression :
```dart
@override
void dispose() {
  // Sauvegarder la position avant de quitter
  final position = _controller.selection.baseOffset;
  LocalDatabaseService().saveProgress(widget.publication.id, position);
  super.dispose();
}
```

---

## 🚀 Étapes d'Implémentation

### **Phase 1 : Configuration de Base**
1. Ajouter `sqflite` et `path` dans `pubspec.yaml`
2. Créer `local_database_service.dart`
3. Tester la création de la DB avec `flutter run`

### **Phase 2 : Remplacement des Services**
1. Modifier `PublicationService` pour utiliser la DB locale
2. Tester l'affichage des publications

### **Phase 3 : Fonctionnalités Avancées**
1. Implémenter les favoris locaux
2. Implémenter la progression de lecture
3. Gérer le stockage des images

### **Phase 4 : Simplification**
1. Retirer ou simplifier l'authentification
2. Retirer les dépendances inutiles (`dio`, appels HTTP)
3. Nettoyer le code

---

## 📦 Pré-Empaqueter du Contenu

Pour inclure du contenu dans l'APK dès l'installation :

### **Option 1 : JSON Assets**
1. Créer `assets/publications.json` :
```json
[
  {
    "titre": "Méditation du Jour",
    "type": "Méditation",
    "contenuPrincipal": "...",
    "extrait": "..."
  }
]
```

2. Dans `pubspec.yaml` :
```yaml
flutter:
  assets:
    - assets/publications.json
    - assets/images/
```

3. Charger au premier lancement :
```dart
Future<void> loadInitialContent() async {
  final jsonString = await rootBundle.loadString('assets/publications.json');
  final List<dynamic> data = json.decode(jsonString);
  
  final db = LocalDatabaseService();
  for (var item in data) {
    await db.addPublication(Publication.fromJson(item));
  }
}
```

---

## ⚡ Avantages du Mode Offline

✅ **Utilisation sans internet** : Parfait pour les lieux sans réseau  
✅ **Rapidité** : Pas de latence réseau  
✅ **Confidentialité** : Données stockées uniquement sur l'appareil  
✅ **Économie de données** : Pas de consommation data  
✅ **Coût zéro** : Pas besoin de serveur backend  

---

## 🔄 Mode Hybride (Optionnel)

Si vous voulez garder une synchronisation cloud optionnelle :

1. **Fonctionnement normal** : 100% offline
2. **Bouton "Synchroniser"** : Upload des favoris/progression vers le cloud
3. **Téléchargement de contenu** : Récupérer de nouvelles publications depuis le serveur

```dart
class SyncService {
  Future<void> syncToCloud() async {
    if (await _hasInternetConnection()) {
      final localPubs = await LocalDatabaseService().getPublications();
      // Upload vers le serveur
      await uploadToServer(localPubs);
    }
  }
  
  Future<void> syncFromCloud() async {
    if (await _hasInternetConnection()) {
      final cloudPubs = await fetchFromServer();
      // Sauvegarder localement
      for (var pub in cloudPubs) {
        await LocalDatabaseService().addPublication(pub);
      }
    }
  }
}
```

---

## 📝 Checklist de Migration

- [ ] Installer `sqflite`
- [ ] Créer `LocalDatabaseService`
- [ ] Modifier `PublicationService`
- [ ] Tester l'affichage des publications offline
- [ ] Implémenter les favoris locaux
- [ ] Implémenter la progression de lecture
- [ ] Stocker les images localement
- [ ] Simplifier/Retirer l'authentification
- [ ] Tester l'APK en mode avion
- [ ] Documenter pour les utilisateurs

---

Voulez-vous que je commence à implémenter ces modifications ?

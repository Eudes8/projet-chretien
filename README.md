# Projet Chrétien - Application Native

## Nouvelle Architecture (Native & Premium)

Ce projet a été refondu pour utiliser des solutions natives légères et performantes, remplaçant Strapi par une API Node.js sur mesure.

### 1. Backend (API Native)
Le backend est situé dans le dossier `backend-native`. Il utilise Node.js, Express et SQLite.

**Démarrage :**
```bash
cd backend-native
npm install  # Une seule fois
node server.js
```
Le serveur démarrera sur `http://localhost:3000`.

### 2. Frontend (Application Flutter)
L'application mobile est située dans le dossier `frontend`. Elle a été redesignée avec un thème "Royal" (Bleu Profond & Or) et une navigation native.

**Démarrage :**
```bash
cd frontend
flutter pub get # Une seule fois
flutter run
```

### 3. Débogage sur Téléphone Physique (Android)
Si vous utilisez un téléphone Android branché en USB, vous devez rediriger le port 3000 pour que le téléphone puisse accéder au backend de votre ordinateur.

Exécutez cette commande dans votre terminal (nécessite ADB installé, inclus avec Android Studio) :
```bash
adb reverse tcp:3000 tcp:3000
```

### Fonctionnalités Clés
- **Design Premium** : Thème bleu profond et or, polices Google Fonts (Libre Baskerville, Lato).
- **Lecture Audio** : Text-to-Speech natif avec surlignage du texte.
- **Mode Admin** : Intégré dans l'application (via l'écran "Compte") pour ajouter/modifier des publications sans outil externe.
- **Bibliothèque** : Vue en grille avec gestion des images.
- **Performance** : Backend ultra-léger (< 50 Mo RAM) et base de données locale SQLite.

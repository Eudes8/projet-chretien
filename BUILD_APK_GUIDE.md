# 📱 GUIDE COMPLET - CRÉATION APK ANDROID

## 📋 TABLE DES MATIÈRES
1. [Prérequis](#prérequis)
2. [Configuration Initiale](#configuration-initiale)
3. [Build APK de Test](#build-apk-de-test)
4. [Build APK de Production](#build-apk-de-production)
5. [Build AAB pour Play Store](#build-aab-pour-play-store)
6. [Troubleshooting](#troubleshooting)

---

## ✅ PRÉREQUIS

### Outils Nécessaires
- ✅ Flutter SDK (déjà installé)
- ✅ Android Studio ou Android SDK
- ✅ Java JDK 17+
- ⚠️ Signing key (pour production)

### Vérification Rapide
```bash
flutter doctor -v
```

---

## 🔧 CONFIGURATION INITIALE

### 1. **Vérifier `pubspec.yaml`**

Ouvrez `frontend/pubspec.yaml` et vérifiez/modifiez :

```yaml
name: projet_chretien
description: Application chrétienne de méditations et livres spirituels
publish_to: 'none'
version: 1.0.0+1  # Format: version+buildNumber

environment:
  sdk: '>=3.0.0 <4.0.0'
```

### 2. **Configuration Android Manifest**

**Fichier**: `frontend/android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.votredomaine.projet_chretien">
    
    <!-- Permissions Internet (déjà présent normalement) -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    
    <application
        android:label="Méditations Chrétiennes"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Configuration du réseau pour http (dev) -->
        android:usesCleartextTraffic="true"
        
        <!-- ... reste du fichier ... -->
    </application>
</manifest>
```

### 3. **Configuration Gradle**

**Fichier**: `frontend/android/app/build.gradle`

Modifiez les sections suivantes :

```gradle
android {
    namespace "com.votredomaine.projet_chretien"
    compileSdk 34  // Flutter 3.24+ requiert 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId "com.votredomaine.projet_chretien"
        minSdkVersion 21  // Android 5.0+
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug  // Pour test, voir section production
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

---

## 🚀 BUILD APK DE TEST

### Méthode Rapide (Debug Build)

```bash
cd frontend
flutter build apk --debug
```

**Sortie**: `frontend/build/app/outputs/flutter-apk/app-debug.apk`

### Avantages du Debug APK
- ✅ Rapide à construire
- ✅ Pas besoin de signing key
- ✅ Parfait pour tests internes
- ⚠️ **Taille plus grande** (~50-100 MB)
- ⚠️ **Performances réduites**

### Installation sur Téléphone

**Méthode 1 : USB**
```bash
flutter install
```

**Méthode 2 : Transfert Manuel**
1. Copiez `app-debug.apk` sur votre téléphone
2. Activez "Sources inconnues" dans Paramètres > Sécurité
3. Ouvrez le fichier APK et installez

---

## 🏆 BUILD APK DE PRODUCTION

### 1. **Créer une Signing Key**

⚠️ **IMPORTANT** : Gardez ces fichiers en sécurité !

```bash
cd frontend/android/app

keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Questions Posées** :
- Password : `[CHOISISSEZ UN MOT DE PASSE FORT]`
- Prénom/Nom : `[Votre Nom]`
- Organisation : `[Votre Organisation]`
- Ville : `[Votre Ville]`
- Pays : `FR`

### 2. **Configuration du Signing**

Créez `frontend/android/key.properties` :

```properties
storePassword=[VOTRE_MOT_DE_PASSE]
keyPassword=[VOTRE_MOT_DE_PASSE]
keyAlias=upload
storeFile=keystore.jks
```

⚠️ **IMPORTANT** : Ajoutez à `.gitignore` :
```
android/key.properties
android/app/keystore.jks
```

### 3. **Modifiez `build.gradle`**

**Fichier**: `frontend/android/app/build.gradle`

Ajoutez **AVANT** `android {` :

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... (configuration existante)
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release  // ← MODIFIÉ
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### 4. **Build Production APK**

```bash
cd frontend
flutter clean
flutter pub get
flutter build apk --release
```

**Sortie**: `frontend/build/app/outputs/flutter-apk/app-release.apk`

### Avantages du Release APK
- ✅ Optimisé pour performance
- ✅ Taille réduite (~20-40 MB)
- ✅ Signé avec votre clé
- ✅ Prêt pour distribution

---

## 📦 BUILD AAB (ANDROID APP BUNDLE)

**Recommandé pour Google Play Store**

```bash
flutter build appbundle --release
```

**Sortie**: `frontend/build/app/outputs/bundle/release/app-release.aab`

### Avantages AAB
- ✅ **Taille optimale** pour chaque appareil
- ✅ **Requis** par Play Store depuis août 2021
- ✅ Google génère des APK optimisés par appareil

---

## 🎨 PERSONNALISATION

### Icône de l'Application

**Option 1 : Package `flutter_launcher_icons`**

1. Ajoutez dans `pubspec.yaml` :
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

2. Placez votre icône (1024x1024 PNG) dans `assets/icon/`

3. Générez :
```bash
dart run flutter_launcher_icons
```

**Option 2 : Manuel**
Remplacez les fichiers dans `android/app/src/main/res/mipmap-*/`

### Splash Screen

**Package**: `flutter_native_splash`

1. Ajoutez dans `pubspec.yaml` :
```yaml
dev_dependencies:
  flutter_native_splash: ^2.3.5

flutter_native_splash:
  android: true
  ios: false
  color: "#1A237E"
  image: "assets/splash.png"
  android_12:
    color: "#1A237E"
    image: "assets/splash.png"
```

2. Générez :
```bash
dart run flutter_native_splash:create
```

---

## 🐛 TROUBLESHOOTING

### Erreur : "Gradle build failed"

**Solution 1** : Nettoyage
```bash
cd frontend/android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

**Solution 2** : Java Version
```bash
java -version  # Doit être 17 ou +
```

### Erreur : "SDK version mismatch"

Modifiez `android/app/build.gradle` :
```gradle
compileSdk 34
targetSdkVersion 34
```

### Erreur : "Signing key not found"

Vérifiez :
```bash
ls android/app/keystore.jks  # Le fichier existe ?
cat android/key.properties    # Les chemins sont corrects ?
```

### APK trop volumineux

**Solutions** :
- ✅ Utilisez AAB au lieu d'APK
- ✅ Activez `shrinkResources` et `minifyEnabled`
- ✅ Supprimez les assets inutilisés
- ✅ Compressez les images

```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

---

## 📝 CHECKLIST FINALE

Avant de publier :

### Technique
- [ ] Version et buildNumber mis à jour dans `pubspec.yaml`
- [ ] Icône personnalisée installée
- [ ] Splash screen configuré
- [ ] Permissions nécessaires dans AndroidManifest
- [ ] Tests sur plusieurs appareils Android
- [ ] Tests sur différentes versions d'Android (min 5.0)

### Contenu
- [ ] Nom de l'app finalisé
- [ ] Description courte (80 caractères max)
- [ ] Description longue (4000 caractères max)
- [ ] Screenshots (2-8 images)
- [ ] Bannière/Header image
- [ ] Politique de confidentialité
- [ ] Catégorie définie (Books & Reference)

### Legal
- [ ] Politique de confidentialité publiée
- [ ] Conditions d'utilisation
- [ ] Copyright et mentions légales

---

## 🚀 COMMANDES RAPIDES

```bash
# Build Debug (test rapide)
flutter build apk --debug

# Build Release APK (distribution)
flutter build apk --release

# Build AAB (Play Store)
flutter build appbundle --release

# Build multi-architecture (plus gros mais compatible)
flutter build apk --split-per-abi --release

# Installation directe
flutter install

# Nettoyage complet
flutter clean && flutter pub get
```

---

## 📊 TAILLES APPROXIMATIVES

| Type | Taille (MB) | Usage |
|------|------------|-------|
| Debug APK | 50-100 | Tests internes uniquement |
| Release APK | 20-40 | Distribution directe |
| AAB | 15-30 | Play Store (recommend é) |
| APK per-ABI | 15-25 chacun | Distribution optimisée |

---

## 🎯 PROCHAINES ÉTAPES

1. **Aujourd'hui** : Build APK de test
   ```bash
   flutter build apk --debug
   ```

2. **Avant publication** : 
   - Créer signing key
   - Build APK/AAB de production
   - Tests complets

3. **Publication** :
   - Créer compte Google Play Console (25$ one-time)
   - Soumettre AAB
   - Attendre validation (2-3 jours)

---

*Guide créé le 24 novembre 2024*
*Version: 1.0*

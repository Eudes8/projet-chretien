# 🚀 BUILD APK VIA GITHUB ACTIONS

## ✅ Configuration Terminée !

Un workflow GitHub Actions a été créé dans `.github/workflows/build-apk.yml` qui construira automatiquement votre APK dans le cloud.

---

## 📋 ÉTAPES POUR OBTENIR VOTRE APK

### 1️⃣ **Initialiser Git (si pas déjà fait)**

```bash
cd C:\Users\DELL\Desktop\LOGICIEL\projet-chretien
git init
git add .
git commit -m "Initial commit with GitHub Actions workflow"
```

### 2️⃣ **Créer un Repository GitHub**

1. Allez sur https://github.com/new
2. Nom du repo : `projet-chretien` (ou autre nom)
3. **NE PAS** cocher "Initialize with README"
4. Cliquez "Create repository"

### 3️⃣ **Pousser le Code sur GitHub**

```bash
git remote add origin https://github.com/VOTRE_USERNAME/projet-chretien.git
git branch -M main
git push -u origin main
```

### 4️⃣ **Lancer le Build**

**Option A : Automatique**
- Le workflow se lance automatiquement dès que vous poussez le code

**Option B : Manuel**
1. Allez sur votre repo GitHub
2. Cliquez sur l'onglet **"Actions"**
3. Sélectionnez **"Build Android APK"**
4. Cliquez sur **"Run workflow"** > **"Run workflow"**

### 5️⃣ **Télécharger l'APK**

1. Attendez 5-10 minutes (le build se fait dans le cloud)
2. Une fois terminé (✅ vert), cliquez sur le workflow
3. Descendez jusqu'à **"Artifacts"**
4. Téléchargez :
   - **app-debug** : APK de test (~50 MB)
   - **app-release** : APK de production (~15-20 MB par architecture)

---

## 🎯 AVANTAGES DE CETTE MÉTHODE

✅ **Pas de problème local** : Build dans un environnement propre Ubuntu  
✅ **Rapide** : 5-10 minutes au lieu de 20+ minutes localement  
✅ **Reproductible** : Même résultat à chaque fois  
✅ **Multi-architecture** : Génère des APK optimisés (arm64-v8a, armeabi-v7a, x86_64)  
✅ **Gratuit** : 2000 minutes/mois sur GitHub Actions (largement suffisant)  

---

## 🔧 ALTERNATIVE : BUILD LOCAL DIRECT

Si vous voulez quand même essayer en local, voici la commande la plus simple :

```bash
cd frontend
flutter build apk --debug --no-shrink
```

L'option `--no-shrink` désactive l'optimisation qui peut causer des problèmes.

---

## 📱 INSTALLATION SUR ANDROID

Une fois l'APK téléchargé :

1. **Transférez** le fichier APK sur votre téléphone Android
2. **Activez** "Sources inconnues" dans Paramètres > Sécurité
3. **Ouvrez** le fichier APK
4. **Installez** l'application

---

## 🆘 BESOIN D'AIDE ?

Si vous n'avez pas de compte GitHub ou préférez une autre solution :
- **Option A** : Je peux créer un script qui utilise Codemagic (service similaire)
- **Option B** : Je peux essayer un build local avec des paramètres différents
- **Option C** : Build Web (PWA) qui fonctionne sur mobile

---

*Créé le 25 novembre 2024*

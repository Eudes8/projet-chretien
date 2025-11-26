# 🚀 GUIDE COMPLET DE DÉPLOIEMENT

## ✅ ÉTAT ACTUEL

Votre application est **prête à être déployée** ! Tous les fichiers nécessaires sont en place :

- ✅ `Dockerfile` - Pour le backend Node.js
- ✅ `render.yaml` - Configuration Render.com
- ✅ `.github/workflows/deploy.yml` - Déploiement automatique du frontend
- ✅ Toutes les fonctionnalités implémentées ou avec message "Bientôt disponible"

---

## 📱 OPTION 1 : UTILISER L'APP SANS SERVEUR 24/7

### Solution : Déployer le backend sur un service cloud GRATUIT

Vous avez 3 options gratuites :

### A. Render.com (RECOMMANDÉ - Le plus simple)

**Avantages** :
- 100% gratuit pour toujours
- Déploiement automatique depuis GitHub
- SSL/HTTPS inclus
- Redémarre automatiquement après inactivité

**Étapes** :

1. **Créer un compte**
   - Allez sur https://render.com
   - Cliquez "Get Started"
   - Connectez-vous avec GitHub

2. **Créer le service**
   - Cliquez "New +" → "Web Service"
   - Sélectionnez votre repo `projet-chretien`
   - Configurez :
     ```
     Name: projet-chretien-backend
     Branch: master
     Environment: Docker
     Dockerfile Path: Dockerfile
     Plan: Free
     ```

3. **Variables d'environnement**
   - Cliquez "Environment" → "Add Environment Variable"
   - Ajoutez :
     ```
     JWT_SECRET = votre_secret_aleatoire_123456789
     PORT = 3000
     ```

4. **Déployer**
   - Cliquez "Create Web Service"
   - Attendez 2-3 minutes
   - Notez l'URL : `https://projet-chretien-backend.onrender.com`

5. **Mettre à jour le frontend**
   - Ouvrez `frontend/lib/services/auth_service.dart`
   - Changez `baseURL: 'http://192.168.1.8:3000'` 
   - Par `baseURL: 'https://projet-chretien-backend.onrender.com'`
   - Faites de même dans `payment_service.dart`
   - Commit et push

---

### B. Railway.app (Alternative)

1. Allez sur https://railway.app
2. "Start a New Project" → "Deploy from GitHub repo"
3. Sélectionnez `projet-chretien`
4. Railway détecte automatiquement le Dockerfile
5. Ajoutez les variables d'environnement
6. Déployez !

---

### C. Fly.io (Plus technique mais puissant)

```bash
# Installez Fly CLI
powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"

# Connectez-vous
fly auth login

# Depuis le dossier du projet
cd backend-native
fly launch --dockerfile ../Dockerfile
fly deploy
```

---

## 🌐 OPTION 2 : DÉPLOYER LE FRONTEND

### GitHub Pages (Gratuit et automatique)

**C'est déjà configuré !** Le fichier `.github/workflows/deploy.yml` est en place.

**Étapes** :

1. **Activer GitHub Pages**
   - Allez sur votre repo GitHub
   - Settings → Pages
   - Source : "GitHub Actions"

2. **Le workflow se lance automatiquement**
   - À chaque push sur `master`
   - Compile le Flutter Web
   - Déploie sur GitHub Pages

3. **Votre URL sera** :
   ```
   https://<votre-nom-utilisateur>.github.io/projet-chretien/
   ```

4. **Vérifier le déploiement**
   - Onglet "Actions" sur GitHub
   - Vérifiez que le workflow "Deploy Flutter Web to GitHub Pages" est vert

---

## 🔧 CONFIGURATION FINALE

### 1. Mettre à jour l'URL du backend dans le frontend

**Fichiers à modifier** :

`frontend/lib/services/auth_service.dart` :
```dart
final Dio _dio = Dio(BaseOptions(
  baseURL: 'https://VOTRE-URL-RENDER.onrender.com', // ← Changez ici
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 3),
));
```

`frontend/lib/services/payment_service.dart` :
```dart
final Dio _dio = Dio(BaseOptions(
  baseURL: 'https://VOTRE-URL-RENDER.onrender.com', // ← Changez ici
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 3),
));
```

`frontend/lib/services/publication_service.dart` :
```dart
final Dio _dio = Dio(BaseOptions(
  baseURL: 'https://VOTRE-URL-RENDER.onrender.com', // ← Changez ici
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 3),
));
```

### 2. Commit et push

```bash
git add .
git commit -m "Update API URLs for production deployment"
git push
```

Le workflow GitHub Actions se déclenchera automatiquement et déploiera le frontend.

---

## ✅ CHECKLIST FINALE

- [ ] Backend déployé sur Render/Railway/Fly
- [ ] URL du backend notée
- [ ] URLs mises à jour dans le frontend
- [ ] Frontend poussé sur GitHub
- [ ] GitHub Pages activé
- [ ] Workflow GitHub Actions passé (vert)
- [ ] Test : Ouvrir l'URL GitHub Pages
- [ ] Test : S'inscrire avec un nouveau compte
- [ ] Test : Se connecter
- [ ] Test : Voir les publications
- [ ] Test : Tester l'abonnement Premium
- [ ] Test : Vérifier le contenu payant verrouillé

---

## 🎉 RÉSULTAT FINAL

Une fois ces étapes terminées, vous aurez :

✅ **Backend** : Hébergé gratuitement sur le cloud, accessible 24/7
✅ **Frontend** : Déployé sur GitHub Pages, accessible depuis n'importe où
✅ **Base de données** : SQLite embarquée (pour dev) ou PostgreSQL (pour prod)
✅ **SSL/HTTPS** : Inclus gratuitement
✅ **Déploiement continu** : Chaque push déploie automatiquement

**Votre app est maintenant accessible publiquement !**

---

## 📞 SUPPORT

Si vous rencontrez des problèmes :

1. **Backend ne démarre pas** :
   - Vérifiez les logs sur Render/Railway
   - Vérifiez que `JWT_SECRET` est défini
   - Vérifiez que le port est bien 3000

2. **Frontend ne se connecte pas au backend** :
   - Vérifiez l'URL dans les services Dart
   - Vérifiez que le backend répond (testez avec `curl`)
   - Vérifiez les CORS (normalement OK avec Express)

3. **GitHub Actions échoue** :
   - Vérifiez les logs dans l'onglet Actions
   - Vérifiez que Flutter est bien installé
   - Vérifiez que `pubspec.yaml` est valide

---

## 🚀 PROCHAINES ÉTAPES (Optionnel)

1. **Domaine personnalisé** : Configurez un nom de domaine (ex: `monapp.com`)
2. **Base de données PostgreSQL** : Migrez de SQLite vers PostgreSQL (Render offre un plan gratuit)
3. **CDN pour les images** : Utilisez Cloudinary ou AWS S3
4. **Analytics** : Ajoutez Google Analytics ou Plausible
5. **Monitoring** : Configurez Sentry pour les erreurs
6. **Tests automatisés** : Ajoutez des tests unitaires et d'intégration

Bonne chance ! 🎊

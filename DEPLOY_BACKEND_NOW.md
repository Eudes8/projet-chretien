# 🚀 DÉPLOYER LE BACKEND MAINTENANT (5 minutes)

## Option 1 : Render.com (RECOMMANDÉ - 100% Gratuit)

### Étapes :
1. Allez sur https://render.com
2. Cliquez "Get Started" → Connectez-vous avec GitHub
3. Cliquez "New +" → "Web Service"
4. Sélectionnez votre repo `projet-chretien`
5. Configurez :
   - **Name**: `projet-chretien-backend`
   - **Branch**: `master`
   - **Root Directory**: laissez vide
   - **Environment**: `Docker`
   - **Dockerfile Path**: `Dockerfile`
   - **Plan**: `Free`

6. Variables d'environnement (cliquez "Add Environment Variable") :
   ```
   JWT_SECRET = votre_secret_aleatoire_123456
   PORT = 3000
   ```

7. Cliquez "Create Web Service"

### ✅ Résultat :
Vous obtiendrez une URL type : `https://projet-chretien-backend.onrender.com`

**IMPORTANT** : Notez cette URL, vous en aurez besoin pour le frontend !

---

## Option 2 : Railway.app (Alternative gratuite)

1. Allez sur https://railway.app
2. "Start a New Project" → "Deploy from GitHub repo"
3. Sélectionnez `projet-chretien`
4. Railway détecte automatiquement le Dockerfile
5. Ajoutez les variables d'environnement dans Settings
6. Déployez !

---

## Option 3 : Fly.io (Plus technique mais puissant)

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

## 📱 Après le déploiement

Une fois le backend déployé, vous devez mettre à jour le frontend pour pointer vers la nouvelle URL.

Je vais créer un fichier de configuration pour cela.

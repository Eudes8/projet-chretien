# 🔧 Migration SQLite → PostgreSQL sur Render

## Le Problème

Sur Render Free Tier, **SQLite n'est pas persistant**. Les données sont perdues à chaque redémarrage.

## La Solution : PostgreSQL

Render offre **PostgreSQL gratuit** avec 1 GB de stockage persistant.

---

## 📋 Étapes de Migration

### 1. Créer une Base PostgreSQL sur Render

1. Allez sur [render.com](https://dashboard.render.com)
2. Cliquez sur **"New +"** → **"PostgreSQL"**
3. Paramètres :
   - **Name** : `projet-chretien-db`
   - **Database** : `projet_chretien`
   - **User** : `projet_chretien_user`
   - **Region** : `Frankfurt (Europe)`
   - **Plan** : **Free**
4. Cliquez sur **"Create Database"**
5. **Notez l'URL de connexion** : `postgres://user:password@host/database`

### 2. Installer le Driver PostgreSQL

Dans `backend-native/package.json`, ajouter :

```json
{
  "dependencies": {
    "pg": "^8.11.3",
    "pg-hstore": "^2.3.4"
  }
}
```

### 3. Modifier `database.js`

**Avant (SQLite)** :
```javascript
const sequelize = new Sequelize({
  dialect: 'sqlite',
  storage: './database.sqlite'
});
```

**Après (PostgreSQL)** :
```javascript
const sequelize = new Sequelize(process.env.DATABASE_URL || 'sqlite::memory:', {
  dialect: process.env.DATABASE_URL ? 'postgres' : 'sqlite',
  dialectOptions: process.env.DATABASE_URL ? {
    ssl: {
      require: true,
      rejectUnauthorized: false
    }
  } : {},
  logging: false
});
```

### 4. Configurer la Variable d'Environnement

Sur Render (votre service backend) :
1. **Settings** → **Environment**
2. Ajouter :
   - **Key** : `DATABASE_URL`
   - **Value** : L'URL PostgreSQL copiée de l'étape 1
3. **Save Changes**

### 5. Redéployer

Le backend se redéploie automatiquement et utilise PostgreSQL.

---

## 🎯 Avantages

✅ **Persistance** : Les données ne sont plus perdues  
✅ **Gratuit** : Free tier de Render  
✅ **Performance** : PostgreSQL est plus rapide que SQLite pour le multi-utilisateurs  
✅ **Scalabilité** : Prêt pour la production  
✅ **Backups** : Sauvegardes automatiques  

---

## 🔄 Migration Automatique des Schémas

Sequelize va automatiquement :
1. Créer les tables dans PostgreSQL
2. Appliquer les mêmes modèles (User, Publication, etc.)
3. Ré-initialiser l'admin par défaut

**Pas besoin de migration manuelle !**

---

## ⚡ Action Rapide (Copier-Coller)

### Commandes à exécuter :

```bash
# 1. Installer PostgreSQL driver
cd backend-native
npm install pg pg-hstore

# 2. Commit et push
git add package.json
git commit -m "feat: Add PostgreSQL support"
git push
```

### Code à remplacer dans `backend-native/database.js` :

```javascript
const { Sequelize } = require('sequelize');

// Configuration avec support PostgreSQL et SQLite (fallback)
const sequelize = new Sequelize(process.env.DATABASE_URL || 'sqlite::memory:', {
  dialect: process.env.DATABASE_URL ? 'postgres' : 'sqlite',
  dialectOptions: process.env.DATABASE_URL ? {
    ssl: {
      require: true,
      rejectUnauthorized: false
    }
  } : {},
  storage: process.env.DATABASE_URL ? undefined : './database.sqlite',
  logging: false,
});

module.exports = sequelize;
```

---

## 🚨 Important

Après la migration :
1. **Reconnectez-vous** à l'app (les users seront réinitialisés)
2. **Recréez du contenu** (les publications seront vides)
3. **Testez la persistance** : Redémarrez le service et vérifiez que les données restent

---

## 📞 Besoin d'Aide ?

Je peux automatiser tout ça pour vous. Voulez-vous que je :
- [ ] Modifie automatiquement `database.js`
- [ ] Installe les dépendances
- [ ] Pousse le code
- [ ] Crée la base PostgreSQL sur Render pour vous (nécessite vos identifiants)

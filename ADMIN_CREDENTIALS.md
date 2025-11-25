# 🔐 Authentification Admin

## Identifiants par défaut

**Username:** `admin`  
**Password:** `Admin@2024!`

## Comment utiliser le Mode Admin

1. **Accéder au Mode Admin :**
   - Lancez l'application Flutter
   - Allez dans l'onglet "Compte" (icône de profil)
   - Cliquez sur "Mode Admin"

2. **Connexion :**
   - Vous serez redirigé vers l'écran de connexion
   - Entrez les identifiants ci-dessus
   - Cliquez sur "Se connecter"

3. **Gestion des Publications :**
   - Une fois connecté, vous pouvez :
     - ✅ Créer de nouvelles publications (bouton +)
     - ✏️ Modifier des publications existantes
     - 🗑️ Supprimer des publications

## Sécurité

### Token JWT
- Le token d'authentification est valide pendant **24 heures**
- Il est stocké en mémoire (perdu au redémarrage de l'app)
- Toutes les opérations de création/modification/suppression nécessitent ce token

### Endpoints protégés
- `POST /publications` - Créer une publication
- `PUT /publications/:id` - Modifier une publication
- `DELETE /publications/:id` - Supprimer une publication

### Endpoints publics
- `GET /publications` - Lister toutes les publications
- `GET /publications/:id` - Voir une publication

## ⚠️ IMPORTANT - Production

**Avant de déployer en production, vous DEVEZ :**

1. **Changer le mot de passe par défaut**
2. **Modifier le JWT_SECRET** dans `backend-native/middleware/auth.js`
3. **Utiliser des variables d'environnement** pour les secrets
4. **Activer HTTPS** pour sécuriser les communications

## Créer un nouvel administrateur

Pour créer un compte admin supplémentaire, utilisez l'endpoint (nécessite d'être déjà connecté) :

```bash
POST http://localhost:3000/auth/register
Headers: Authorization: Bearer <votre_token>
Body: {
  "username": "nouvel_admin",
  "password": "MotDePasseSecurise123!"
}
```

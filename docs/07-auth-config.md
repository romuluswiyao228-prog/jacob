# Configuration Supabase Auth — JACOB DE JESUS

## Réglages à effectuer dans le tableau de bord Supabase

### 1. URL du site (Site URL)

**Authentication → URL Configuration → Site URL**

Définir l'URL de production de la boutique (ex. `https://jacob-de-jesus.com`).

### 2. URLs de redirection (Redirect URLs)

**Authentication → URL Configuration → Redirect URLs**

Ajouter :
- `https://jacob-de-jesus.com/**` (production)
- `http://localhost:5173/**` (développement local)

### 3. Confirmation d'e-mail

**Authentication → Providers → Email**

Laisser « Confirm email » activé (ON). Les nouveaux utilisateurs
reçoivent un e-mail de confirmation et doivent cliquer sur le lien
avant de pouvoir se connecter. L'application gère ce flux : après
l'inscription, un message demande à l'utilisateur de vérifier sa
boîte de réception. La tentative de connexion avant confirmation
affiche « Veuillez confirmer votre e-mail avant de vous connecter. »

### 4. Modèles d'e-mails (français)

**Authentication → Email Templates**

Personnaliser le modèle « Confirm signup » :

- Subject : `Confirmez votre inscription — JACOB DE JESUS`
- Body :
  ```
  Bonjour,

  Bienvenue sur JACOB DE JESUS ! Pour activer votre compte,
  cliquez sur le lien ci-dessous :

  {{ .ConfirmationURL }}

  — L'équipe JACOB DE JESUS
  ```

Personnaliser le modèle « Reset password » :

- Subject : `Réinitialisation de votre mot de passe — JACOB DE JESUS`
- Body :
  ```
  Bonjour,

  Vous avez demandé la réinitialisation de votre mot de passe.
  Cliquez sur le lien ci-dessous pour en choisir un nouveau :

  {{ .ConfirmationURL }}

  Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.

  — L'équipe JACOB DE JESUS
  ```

Les modèles « Invite » et « Magic Link » ne sont pas utilisés
(authentification par mot de passe uniquement).

### 5. MFA (authentification à deux facteurs)

**Authentication → MFA**

Laisser les réglages par défaut. La MFA TOTP est activée individuellement
par le propriétaire depuis la page `/admin/mfa-setup`. La vérification du
niveau AAL (`aal2`) est effectuée côté base de données par la fonction
`is_admin_aal2()` dans toutes les politiques RLS d'administration.

### Note importante : garde UI vs protection réelle

Les composants `RequireAuth` et `RequireAdmin` dans l'interface améliorent
l'expérience utilisateur en redirigeant les visiteurs non autorisés. La
vraie protection est assurée par les politiques RLS au niveau de la base
de données via `is_admin_aal2()`. Un propriétaire sans MFA validée (aal1)
ne peut ni lire ni modifier aucune donnée d'administration, même en
contournant l'interface.

# SongTaaba 🎓

> **SongTaaba** (qui signifie *"l'entraide"* en mooré) est une plateforme de gestion des opportunités de bourses d'études et de stages. Elle aide les étudiants à découvrir, suivre et postuler aux bourses disponibles localement et internationalement, grâce au scraping automatique de sites spécialisés.

---

## Table des matières

- [Présentation](#présentation)
- [Fonctionnalités](#fonctionnalités)
- [Stack technique](#stack-technique)
- [Installation & configuration](#installation--configuration)
- [Structure du projet](#structure-du-projet)
- [Endpoints API](#endpoints-api)
- [Contribution](#contribution)

---

## Présentation

SongTaaba est une application mobile et web permettant à tout étudiant de :

- **Rechercher** des bourses et stages par niveau d'études, domaine et date limite
- **Découvrir automatiquement** de nouvelles opportunités via le scraping de sites institutionnels et internationaux
- **Suivre** les opportunités qui l'intéressent
- **Recevoir des notifications** pour les nouvelles offres correspondant à son profil
- **Préparer ses dossiers** de candidature avec une assistance intégrée

---

## Fonctionnalités

### Scraping automatique
- Extraction des offres depuis les sites d'institutions éducatives et d'organisations internationales
- Utilisation de **BeautifulSoup** pour parser les contenus web
- Planification des scraping par fréquence configurable par site

### Gestion des opportunités
- Classement par niveau d'études, domaine, pays et date limite
- Recherche et filtrage avancés
- Mise à jour automatique des offres

### Espace étudiant
- Inscription et authentification sécurisée (JWT)
- Suivi personnalisé des bourses d'intérêt
- Statuts de candidature : *intéressé → candidat → accepté / refusé*

### Notifications
- Alertes pour les nouvelles offres correspondant au profil
- Rappels de deadlines

---

## Stack technique

| Couche | Technologie |
|--------|------------|
| Backend | Python 3.12 + Flask 3.1.1 |
| Base de données | PostgreSQL + SQLAlchemy |
| Migrations | Flask-Migrate (Alembic) |
| Authentification | JWT (flask-jwt-extended) |
| Sérialisation | Marshmallow |
| Scraping | BeautifulSoup4 |
| Frontend | Flutter |

---

## Installation & configuration

### Prérequis

- Python 3.12
- PostgreSQL
- Flutter SDK
- pip & virtualenv

### 1. Cloner le projet

```bash
git clone https://github.com/Ghislain-KIMA/SongTaaba.git
cd songtaaba
```

### 2. Configurer le backend

```bash
cd backend
conda create --name env-songtaaba python==3.12
conda activate env-songtaaba
pip install -r requirements.txt
```

### 3. Variables d'environnement

```bash
cp .env.example .env
```

Éditez `.env` avec vos valeurs :

```env
FLASK_ENV=development
SECRET_KEY=your-secret-key
JWT_SECRET_KEY=your-jwt-secret
DATABASE_URL=postgresql://user:password@localhost:5432/songtaaba
```

### 4. Base de données

```bash
flask db init
flask db migrate -m "initial"
flask db upgrade
```

### 5. Lancer le serveur

```bash
python app.py
```

Le serveur démarre sur `http://127.0.0.1:5000`

### 6. Frontend Flutter

```bash
cd frontend
flutter pub get
flutter run
```

---

## Structure du projet

```
songtaaba/
├── README.MD
├── backend/
│   ├── app.py                          # Factory Flask
│   ├── config.py                       # Configurations (dev/prod/test)
│   ├── extensions.py                   # db, ma, jwt, migrate
│   ├── requirements.txt
│   ├── models/
│   │   ├── user.py                     # Modèle utilisateurs
│   │   ├── site.py                     # Modèle sites de scraping
│   │   ├── bourse.py                   # Modèle bourses & stages
│   │   └── users_bourses.py            # Table pivot intérêts/candidatures
│   ├── schemas/
│   │   ├── user_schema.py
│   │   ├── site_schema.py
│   │   ├── bourse_schema.py
│   │   └── users_bourses_schema.py
│   ├── services/
│   │   ├── user_service.py
│   │   ├── bourse_service.py
│   │   ├── site_service.py
│   │   ├── users_bourses_service.py
│   │   └── scraping.py                 # Scraping BeautifulSoup
│   ├── resources/
│   │   ├── user_resource.py
│   │   ├── bourse_resource.py
│   │   ├── site_resource.py
│   │   └── users_bourses_resource.py
│   ├── routes/
│   │   ├── auth_routes.py
│   │   ├── user_routes.py
│   │   ├── bourse_routes.py
│   │   ├── site_routes.py
│   │   └── users_bourses_routes.py
│   ├── migrations/                     # Alembic migrations
│   └── tests/
│       ├── test_auth.py
│       └── test_user.py
├── frontend/
│   ├── lib/
│   │   └── main.dart                   # Point d'entrée Flutter
│   ├── android/
│   ├── ios/
│   ├── linux/
│   ├── macos/
│   ├── web/
│   ├── windows/
│   └── pubspec.yaml
└── docs/
    ├── database/
    │   ├── mcd.png                     # Modèle Conceptuel
    │   ├── mld.png                     # Modèle Logique
    │   └── mpd.png                     # Modèle Physique
    └── ui/
        └── interface.drawio            # Maquettes interfaces
```

---

## Endpoints API

### Authentification

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/api/users/register` | ❌ | Créer un compte |
| POST | `/api/auth/login` | ❌ | Se connecter |
| GET | `/api/auth/me` | ✅ | Profil connecté |

### Utilisateurs

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| GET | `/api/users/` | ✅ | Liste des utilisateurs |
| GET | `/api/users/<id>` | ✅ | Détail d'un utilisateur |
| PUT | `/api/users/<id>` | ✅ | Modifier un utilisateur |
| DELETE | `/api/users/<id>` | ✅ | Supprimer un utilisateur |

### Bourses & Stages

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| GET | `/api/bourses/` | ❌ | Liste des opportunités |
| GET | `/api/bourses/?pays=France` | ❌ | Filtrer par pays |
| GET | `/api/bourses/?niveau=master` | ❌ | Filtrer par niveau |
| GET | `/api/bourses/?type=stage` | ❌ | Filtrer par type |
| GET | `/api/bourses/<id>` | ❌ | Détail d'une opportunité |
| POST | `/api/bourses/` | ✅ | Créer une opportunité |
| PUT | `/api/bourses/<id>` | ✅ | Modifier une opportunité |
| DELETE | `/api/bourses/<id>` | ✅ | Supprimer une opportunité |

### Sites de scraping

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| GET | `/api/sites/` | ✅ | Liste des sites |
| GET | `/api/sites/?actif=true` | ✅ | Sites actifs uniquement |
| POST | `/api/sites/` | ✅ | Ajouter un site |
| PUT | `/api/sites/<id>` | ✅ | Modifier un site |
| DELETE | `/api/sites/<id>` | ✅ | Supprimer un site |

### Candidatures (Users ↔ Bourses)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| GET | `/api/users-bourses/user/<id>` | ✅ | Opportunités d'un étudiant |
| GET | `/api/users-bourses/bourse/<id>` | ✅ | Candidats d'une bourse |
| POST | `/api/users-bourses/` | ✅ | Marquer un intérêt |
| PATCH | `/api/users-bourses/<user_id>/<bourse_id>` | ✅ | Changer le statut |
| DELETE | `/api/users-bourses/<user_id>/<bourse_id>` | ✅ | Retirer un intérêt |

### Statuts de candidature

```
interessé  →  candidat  →  accepté
                        →  refusé
```

### Exemple d'utilisation

```bash
# 1. Créer un compte
curl -X POST http://127.0.0.1:5000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{"nom": "Ouedraogo", "prenom": "Issa", "email": "issa@example.com", "password": "secret123"}'

# 2. Se connecter
curl -X POST http://127.0.0.1:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "issa@example.com", "password": "secret123"}'

# 3. Parcourir les bourses (sans token)
curl http://127.0.0.1:5000/api/bourses/?pays=Canada

# 4. Marquer un intérêt (avec token)
curl -X POST http://127.0.0.1:5000/api/users-bourses/ \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"user_id": "uuid-xxx", "bourse_id": "uuid-yyy", "statut": "interessé"}'
```

---

## Contribution

Les contributions sont les bienvenues ! Voici comment participer :

### 1. Forker le projet

```bash
git clone https://github.com/votre-username/songtaaba.git
```

### 2. Créer une branche

```bash
git checkout -b feature/ma-fonctionnalite
```

### 3. Committer vos changements

```bash
git commit -m "feat: ajouter la fonctionnalité X"
```

### 4. Pousser et ouvrir une Pull Request

```bash
git push origin feature/ma-fonctionnalite
```

### Conventions de commits

| Préfixe | Usage |
|---------|-------|
| `feat:` | Nouvelle fonctionnalité |
| `fix:` | Correction de bug |
| `docs:` | Documentation |
| `refactor:` | Refactoring |
| `scraping:` | Modifications scraping |
| `test:` | Tests |

---

## Critères de succès

- ✅ Augmentation du nombre de candidatures réussies
- ✅ Facilitation de l'accès aux opportunités éducatives
- ✅ Adoption par les étudiants et jeunes professionnels burkinabè et africains

---

## Licence

Ce projet est sous licence **MIT**. Voir le fichier `LICENSE` pour plus de détails.

---

> Fait avec ❤️ pour les étudiants — *SongTaaba, cherchons ensemble.*
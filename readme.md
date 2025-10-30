# 🧩 Projet TEST2 – Supervision d’infrastructure avec Docker, Nginx & SSL

## 🎯 Objectif du projet

Ce projet vise à **mettre en place un environnement de test complet** pour la **supervision d’une infrastructure multi-services** composée de :
- un service de monitoring applicatif (**Uptime Kuma**),
- un service de supervision système et conteneurs (**Netdata**),
- une **base de données Redis** utilisée par Netdata et monitorée par les deux outils,
- un **reverse proxy Nginx** gérant les accès et le routage,
- un système de **certification HTTPS automatisé via Let’s Encrypt**.

Les images sont construites localement puis **poussées sur Docker Hub** pour être déployées sur un environnement de production.

---

## 📂 Structure du projet

```
TEST2/
├── netdata-conf/              # Configuration complète de Netdata
│   ├── go.d/                  # Plugins de monitoring (nginx, redis, docker…)
│   ├── health.d/              # Vérifications de santé personnalisées
│   └── netdata.conf           # Configuration principale
│
├── nginx/
│   └── nginx.conf             # Reverse proxy HTTP/HTTPS + redirection Netdata
│
├── docker-compose.yml         # Environnement de test (build local + SSL auto)
├── Dockerfile                 # Multi-stage build (Kuma, Netdata, Nginx)
└── README.md
```

---

## ⚙️ Description des services (environnement de test)

| Service | Rôle | Détails |
|----------|------|---------|
| **web-monitor (Uptime Kuma)** | Supervision des services web, API et Redis | Importe automatiquement un `backup.json` si la base locale n’existe pas. Permet de suivre la disponibilité de sites web. |
| **netdata** | Monitoring système, Docker et Redis | Affiche en temps réel les ressources CPU, RAM, réseau, disques, et la base Redis grâce aux modules `redis.conf` et `docker.conf` dans `go.d/`. |
| **redis** | Base de données en mémoire pour Netdata | Sert de stockage rapide et est elle-même surveillée par Netdata et Uptime Kuma. |
| **nginx** | Reverse proxy HTTP/HTTPS | Expose Kuma (sous-chemin `/kuma/`) et Netdata (sous-chemin `/netdata/`) en HTTPS. Gère aussi le webroot utilisé par Certbot. |
| **certbot** | Obtention et renouvellement automatique des certificats | Gère les certificats pour `netdatalauba.duckdns.org` et les renouvelle automatiquement. |

---

## 🔧 Fonctionnement global

1. **Uptime Kuma** surveille les services internes : Nginx, Netdata et Redis.  
2. **Netdata** collecte les métriques système, Docker et Redis via les fichiers de configuration dans `netdata-conf/go.d/`.  
3. **Redis** fournit un backend léger pour certaines métriques Netdata et est inclus pour être observé par les deux outils.  
4. **Nginx** centralise l’accès :  
   - `/kuma/` → Uptime Kuma  
   - `/netdata/` → Netdata  
5. **Certbot** obtient un certificat Let’s Encrypt et le renouvelle automatiquement.

---

## 🔨 Déploiement local (environnement de test)

1. **Cloner le projet** :
   ```bash
   git clone https://github.com/netdatalauba.git
   ```

2. **Construire les images personnalisées** :
   ```bash
   docker compose build
   ```

3. **Lancer l’environnement complet** :
   ```bash
   docker compose up -d
   ```

4. **Accès aux services** :
   - **Uptime Kuma** → http://localhost/  
   - **Netdata** → http://localhost/netdata/  
   - **Redis** est interne, mais monitoré par les deux outils.

---

## ☁️ Publication sur Docker Hub

Après validation en local, pousser les images personnalisées :

```bash
docker login

docker tag custom-kuma:eval brdf/custom-kuma:eval
docker tag my-netdata:eval brdf/my-netdata:eval
docker tag custom-nginx:eval brdf/custom-nginx:eval

docker push brdf/custom-kuma:eval
docker push brdf/my-netdata:eval
docker push brdf/custom-nginx:eval
```

---

## 🚀 Déploiement en production

Sur la VM de production (ex : **134.122.109.7**), récupérer le `docker-compose` de production et lancer :

```bash
docker compose up -d
```

Ce compose tirera les images depuis Docker Hub (`brdf/*`) et déploiera l’environnement complet.

### 🔗 Accès public
- **Domaine :** https://netdatalauba.duckdns.org  
- **Uptime Kuma :** `/kuma/`  
- **Netdata :** `/netdata/`

---

## 🔒 Sécurité et certificats

- **Certbot** renouvelle automatiquement les certificats Let’s Encrypt toutes les 12h.  
- Un **certificat auto-signé temporaire** est généré au premier démarrage (via `init-cert`) si aucun certificat n’existe encore, pour permettre à Nginx de démarrer.

---

## 🧱 Volumes persistants

| Volume | Utilisation |
|---------|-------------|
| `kuma-data` | Données persistantes d’Uptime Kuma |
| `netdatalib`, `netdatacache` | Données Netdata et cache |
| `letsencrypt` | Certificats SSL persistants |
| `certbot-www` | Webroot pour validation HTTP |
| `redis-data` *(optionnel)* | Persistance Redis si activée |

---

## 💡 Notes techniques

- **Dockerfile multi-stage :**
  1. **Uptime Kuma** : supervision applicative
  2. **Netdata** : monitoring système et Redis
  3. **Nginx** : reverse proxy + configuration SSL
- Les **fichiers de configuration Netdata (`go.d/redis.conf`, `nginx.conf`, etc.)** permettent de surveiller chaque service individuellement.
- **Redis** est à la fois un service supervisé et un composant technique du monitoring.

---

# 🧩 Advanced Documentation
### Projet : Uptime Kuma + Netdata + Redis + Nginx + Certbot

---

## 1️⃣ Architecture générale

L’environnement repose sur une **infrastructure de supervision conteneurisée** composée de cinq services interconnectés :

| Service | Rôle principal |
|----------|----------------|
| **Uptime Kuma** | Supervision applicative (statut des sites et API) |
| **Netdata** | Supervision système et conteneurs (CPU, mémoire, I/O, réseau, Docker, Redis) |
| **Redis** | Base de données en mémoire utilisée comme backend et cible de monitoring |
| **Nginx** | Reverse proxy unifiant les accès et terminant le HTTPS |
| **Certbot** | Obtention et renouvellement automatique des certificats Let’s Encrypt |

Tous ces services sont définis dans le fichier `docker-compose.yml` et leurs images sont construites via un **Dockerfile multi-stage** (trois étapes distinctes : Kuma, Netdata, Nginx).

L’objectif est de pouvoir :
- **Construire localement** des images personnalisées, testées en environnement de dev.
- **Publier** ces images sur Docker Hub (`brdf/custom-*`).
- **Déployer** en production avec un simple `docker compose up -d`.

---

## 2️⃣ Le Dockerfile multi-stage

Le Dockerfile est découpé en **trois étapes indépendantes** :

### 🟦 Stage 1 – Uptime Kuma

```dockerfile
FROM louislam/uptime-kuma:latest AS kuma
```
- Image de base : version officielle d’Uptime Kuma.  
- Sert de tableau de bord pour le suivi de disponibilité des services internes (Nginx, Redis, Netdata).

```dockerfile
LABEL maintainer="baptiste@example.com"
LABEL org.opencontainers.image.title="Web Service Monitoring Dashboard - Baptiste"
```
- Ajout de métadonnées pour traçabilité (auteur, titre).

```dockerfile
ENV TZ=Europe/Paris
```
- Définit le fuseau horaire des logs.

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3001 || exit 1
```
- Vérifie la santé du service toutes les 30 secondes.
- En cas d’échec répété, le conteneur est marqué `unhealthy`.

```dockerfile
EXPOSE 3001
```
- Indique que l’application écoute sur le port 3001 (interne à Docker).

```dockerfile
RUN echo "Uptime Kuma personnalisé - Projet d’évaluation Docker"
```
- Trace simple confirmant que le build est personnalisé.

---

### 🟩 Stage 2 – Netdata

```dockerfile
FROM netdata/netdata:latest AS netdata
```
- Image officielle Netdata servant de base pour la supervision système.

```dockerfile
RUN mkdir -p /etc/netdata/go.d /etc/netdata/health.d
RUN printf "[global]\n  hostname = MY-NETDATA-EVAL\n" > /etc/netdata/netdata.conf
```
- Préparation des répertoires de configuration des modules et définition d’un nom d’hôte personnalisé.

```dockerfile
COPY netdata-conf/go.d/ /etc/netdata/go.d/
COPY netdata-conf/health.d/ /etc/netdata/health.d/
```
- Copie des configurations personnalisées (plugins Redis, Nginx, Docker, etc.).

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:19999/api/v1/info | grep -q '"version"' || exit 1
```
- Vérifie que l’API Netdata répond correctement.

```dockerfile
EXPOSE 19999
VOLUME ["/var/lib/netdata", "/var/cache/netdata"]
```
- Expose le port Web de Netdata et déclare des volumes persistants pour les données et le cache.

---

### 🟥 Stage 3 – Nginx (Reverse Proxy HTTPS)

```dockerfile
FROM nginx:alpine AS nginx
```
- Image légère (Alpine) utilisée pour le reverse proxy.

```dockerfile
RUN mkdir -p /var/www/certbot
```
- Création du répertoire utilisé par Certbot pour les challenges HTTP-01 de Let’s Encrypt.

```dockerfile
COPY nginx/nginx.conf /etc/nginx/nginx.conf
```
- Remplacement de la configuration Nginx par une version personnalisée :
  - Reverse proxy vers `web-monitor:3001` (Kuma).
  - Reverse proxy vers `netdata:19999` (Netdata) sous `/netdata/`.
  - Gestion des certificats Let’s Encrypt.
  - Redirection HTTP → HTTPS.

```dockerfile
EXPOSE 80 443
```
- Ports utilisés pour le trafic web (HTTP et HTTPS).

---

## 3️⃣ Le fichier docker-compose.yml

Le `docker-compose.yml` assemble les services et définit leur configuration.

### 🔹 Service `web-monitor` (Uptime Kuma)
- **Build** depuis le stage `kuma` du Dockerfile.
- **Volumes** :
  - `kuma-data:/app/data` → stockage persistant des données.
  - `./backup.json` → import initial si base absente.
- **Entrypoint personnalisé** :
  - Restaure la sauvegarde si aucune base `kuma.db` n’existe.
- **Healthcheck** : vérifie la disponibilité locale sur le port 3001.

### 🔹 Service `netdata`
- **Build** depuis le stage `netdata`.
- **Capacités système étendues** :
  - `SYS_PTRACE` + `apparmor:unconfined` pour collecter des métriques détaillées.
- **Volumes** :
  - `netdatalib` / `netdatacache` → données persistantes.
  - `/var/run/docker.sock:ro` → permet à Netdata d’inspecter les conteneurs Docker.
- **depends_on: redis** → assure le démarrage de Redis avant Netdata.

### 🔹 Service `nginx`
- **Build** depuis le stage `nginx`.
- **Ports** : publie 80 (HTTP) et 443 (HTTPS) vers l’extérieur.
- **Volumes** :
  - `certbot-www` : webroot lu par Nginx, écrit par Certbot.
  - `letsencrypt` : dossiers contenant les certificats.
- **depends_on** : attend le lancement de Kuma et Netdata avant de démarrer.

### 🔹 Service `certbot`
- Image officielle `certbot/certbot`.
- **Volumes partagés** avec Nginx :
  - `/var/www/certbot` (écriture des fichiers de challenge).
  - `/etc/letsencrypt` (stockage des certificats).
- **Commandes exécutées** :
  1. Obtention initiale du certificat (`certonly --webroot ...`).
  2. Boucle infinie de renouvellement automatique toutes les 12h.
  3. Rechargement automatique de Nginx après chaque renouvellement.

### 🔹 Service `redis`
- Image `redis:alpine`, version légère.
- Sert à la fois de **base de données en mémoire** pour Netdata et de **cible supervisée**.
- Aucun port n’est exposé (communication interne uniquement).

### 🔹 Volumes persistants
| Volume | Rôle |
|---------|------|
| `kuma-data` | Données d’Uptime Kuma |
| `netdatalib` | Données persistantes Netdata |
| `netdatacache` | Cache de Netdata |
| `certbot-www` | Dossier de challenge ACME |
| `letsencrypt` | Certificats et clés privées |

---

## 4️⃣ Flux HTTPS et renouvellement de certificats

### Étapes du challenge HTTP-01 :
1. Certbot écrit un fichier de vérification sous `/var/www/certbot/.well-known/acme-challenge/`.
2. Nginx sert ce fichier via le port 80 public.
3. Let’s Encrypt vérifie l’URL et délivre le certificat.
4. Certbot stocke les fichiers sous `/etc/letsencrypt/live/<domaine>/`.
5. Nginx utilise ces certificats montés en lecture seule pour le HTTPS.

### Renouvellement automatique :
- Toutes les 12h, Certbot exécute `certbot renew --quiet`.
- Si un certificat est mis à jour :
  - Nginx est rechargé automatiquement (`nginx -s reload`).
  - Le nouveau certificat est immédiatement pris en compte.

---

## 5️⃣ Réseau et communication interne

- Tous les services sont sur le **même réseau Docker par défaut**.
- Docker fournit un **DNS interne** : chaque service est joignable par son nom (`web-monitor`, `netdata`, `redis`).
- Nginx utilise ces noms dans ses directives `proxy_pass` :
  - `http://web-monitor:3001/`
  - `http://netdata:19999/`
- Aucun port interne (3001, 19999, 6379) n’est exposé à l’extérieur, seule Nginx gère le trafic entrant.

---

## 6️⃣ Gestion de la santé et des redémarrages

- Les **healthchecks** intégrés à Kuma et Netdata permettent à Docker de détecter automatiquement un service en panne.
- `restart: unless-stopped` assure la relance automatique en cas d’échec.
- `depends_on` définit l’ordre de démarrage (Redis avant Netdata, etc.).

---

## 7️⃣ Sécurité et bonnes pratiques

- **Principe du moindre privilège :**
  - Nginx monte les certificats en lecture seule.
  - Netdata accède au socket Docker en lecture seule.
- **Certbot** seul a les droits d’écriture sur `/etc/letsencrypt`.
- **AppArmor désactivé** uniquement pour permettre la lecture de certaines métriques système.
- **Aucune donnée sensible** (clé privée, mot de passe) n’est codée en dur.

---

## 8️⃣ Avantages techniques de cette architecture

- **Isolation complète** des composants.
- **Supervision centralisée** des services applicatifs (Kuma) et systèmes (Netdata).
- **Certificats HTTPS automatisés** sans intervention manuelle.
- **Persistance** des données et certificats entre redéploiements.
- **Déploiement reproductible** via Docker Compose (local → prod identique).

---

## 9️⃣ Cycle de vie complet

1. **Build local :**  
   `docker compose build`  
   → génère les images `custom-kuma:eval`, `my-netdata:eval`, `custom-nginx:eval`.

2. **Tests en local :**  
   `docker compose up -d`

3. **Push Docker Hub :**  
   ```bash
   docker tag custom-kuma:eval brdf/custom-kuma:eval
   docker push brdf/custom-kuma:eval
   ```

4. **Déploiement en prod :**  
   Le `docker-compose.yml` de prod tire les images du Docker Hub.

5. **Exploitation :**  
   - Accès web : `https://netdatalauba.duckdns.org`
   - Supervision :  
     - `/kuma/` → Uptime Kuma  
     - `/netdata/` → Netdata  


## 👤 Auteurs

Projet réalisé par :
- **Baptiste D.**
- **Laura T.**

Dans le cadre du module **Docker & Supervision** – *Ynov 2025*.


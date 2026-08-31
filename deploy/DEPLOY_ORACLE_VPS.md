# Déployer le serveur sur un VPS Oracle Cloud Free Tier

> **Note** : Ce fichier est la version publique (sans IP ni chemin de clé privée).
> La version avec tes valeurs réelles est dans `DEPLOY_ORACLE_VPS.local.md` (gitignored).

## Étape 0 — Nom de domaine (gratuit, sans carte)

Let's Encrypt (certbot, étape 7) ne délivre de certificat HTTPS que pour un nom de
domaine, jamais pour une IP brute. **InfinityFree et services similaires ne conviennent
pas** : leurs sous-domaines gratuits pointent vers leurs propres serveurs mutualisés, pas
vers une IP externe de ton choix.

Utilise plutôt **DuckDNS** (duckdns.org), gratuit et sans carte :

1. Connecte-toi avec un compte Google/GitHub/Reddit existant.
2. Choisis un sous-domaine, ex : `mon-club` → tu obtiens `mon-club.duckdns.org`.
3. Une fois ton VPS créé (étape 1), colle son IP publique dans le champ "current ip" de
   DuckDNS et clique "update ip".

Le reste de ce guide utilise `<VOTRE_DOMAINE>.duckdns.org` comme exemple — remplace par
ton propre sous-domaine partout où tu le vois.

## Piège n°1 (celui qui bloque presque tout le monde sur Oracle)

Oracle Cloud a **deux pare-feux séparés** qui doivent tous les deux laisser passer le
trafic : la règle réseau au niveau du cloud (VCN Security List) **et** le pare-feu du
système d'exploitation (`iptables` sur les images Oracle Linux). Ouvrir un port dans un
seul des deux ne suffit pas.

Sur les images **Ubuntu** d'Oracle en particulier, ce n'est en général pas `ufw` qui
bloque (souvent inactif par défaut) mais des règles **`iptables` déjà préconfigurées** à
l'installation, qui n'autorisent que le port 22 (SSH). Symptôme typique côté Certbot :
un **"Timeout during connect"** plutôt qu'un "connection refused" — signature classique
d'un `DROP`/`REJECT` iptables.

## 1. Ouvrir les ports côté Oracle Cloud (console web)

Dans la console OCI : **Networking > Virtual Cloud Networks > (ton VCN) > Security Lists**
→ règle par défaut → **Add Ingress Rules** :

- Port 80 (HTTP, pour la validation Let's Encrypt), source `0.0.0.0/0`
- Port 443 (HTTPS, le trafic réel de l'app), source `0.0.0.0/0`

**Piège spécifique à surveiller** : le champ **Source Port Range doit rester sur `All`**
(vide/tous), à ne pas confondre avec le Destination Port Range (qui, lui, doit être 80 ou
443).

## 2. Ouvrir les ports côté OS (connecté en SSH sur le VPS)

Sur Ubuntu, vérifie d'abord l'état réel des règles :

```bash
sudo iptables -L INPUT -n --line-numbers
```

Repère le numéro de ligne de la règle `REJECT`/`DROP` finale (appelons-le `N`), puis
insère les autorisations juste avant :

```bash
sudo iptables -I INPUT N -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT N -p tcp --dport 443 -j ACCEPT
sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save
```

Si `ufw` est actif, ajoute aussi :

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

Sur Oracle Linux, utilise `firewalld` à la place :

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## 3. Installer Node.js et créer un utilisateur dédié

Sur Ubuntu :

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs
```

Sur Oracle Linux :

```bash
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs
```

Puis, sur les deux :

```bash
sudo useradd -r -s /bin/false hockey
sudo mkdir -p /opt/hockey-club-server /etc/hockey-club /home/hockey
sudo chown hockey:hockey /home/hockey
```

## 4. Copier le projet et la clé de service Firebase

Depuis ta machine locale :

```bash
scp -i <CHEMIN_CLE_SSH> -r server/* <USER>@<IP_VPS>:/tmp/hockey-club-server/
scp -i <CHEMIN_CLE_SSH> <CHEMIN_SERVICE_ACCOUNT>.json <USER>@<IP_VPS>:/tmp/service-account.json
scp -i <CHEMIN_CLE_SSH> -r deploy <USER>@<IP_VPS>:/tmp/deploy
```

> **Remplace** `<CHEMIN_CLE_SSH>`, `<USER>`, `<IP_VPS>` et `<CHEMIN_SERVICE_ACCOUNT>`
> par tes propres valeurs. Voir `DEPLOY_ORACLE_VPS.local.md` pour un exemple concret.

⚠️ **Piège Windows** : `server/*` saute parfois les fichiers commençant par un point
(`.env.example`) selon le shell utilisé. Vérifie après coup avec `ls -la` côté VPS.

Puis sur le VPS :

```bash
sudo mv /tmp/hockey-club-server/* /opt/hockey-club-server/
sudo mv /tmp/service-account.json /etc/hockey-club/service-account.json
sudo chown -R hockey:hockey /opt/hockey-club-server /etc/hockey-club
sudo chmod 600 /etc/hockey-club/service-account.json
```

## 5. Installer les dépendances, configurer, compiler

```bash
cd /opt/hockey-club-server
sudo -u hockey cp .env.example .env
sudo -u hockey nano .env   # vérifie GOOGLE_APPLICATION_CREDENTIALS et PORT
sudo -u hockey npm install
sudo -u hockey npm run build
```

## 6. Lancer en tant que service système (démarrage auto + redémarrage si crash)

```bash
sudo cp /tmp/deploy/hockey-club-server.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now hockey-club-server
sudo systemctl status hockey-club-server   # doit afficher "active (running)"
```

## 7. nginx en reverse proxy + HTTPS automatique

```bash
sudo apt-get install -y nginx certbot python3-certbot-nginx
sudo cp /tmp/deploy/nginx.conf.example /etc/nginx/sites-available/hockey-club
sudo ln -s /etc/nginx/sites-available/hockey-club /etc/nginx/sites-enabled/
sudo nano /etc/nginx/sites-available/hockey-club   # vérifie que ton sous-domaine y figure
sudo systemctl enable --now nginx
sudo certbot --nginx -d <VOTRE_DOMAINE>.duckdns.org
```

## 8. Vérifier que ça tourne

```bash
curl https://<VOTRE_DOMAINE>.duckdns.org/health
# {"status":"ok","time":"..."}
```

## Mettre à jour le code plus tard

```bash
# Depuis ta machine locale — supprime d'abord l'ancien contenu temp côté VPS
ssh -i <CHEMIN_CLE_SSH> <USER>@<IP_VPS> "rm -rf /tmp/src-public /tmp/src-update /tmp/package.json"

scp -i <CHEMIN_CLE_SSH> -r server/public <USER>@<IP_VPS>:/tmp/src-public
scp -i <CHEMIN_CLE_SSH> -r server/src <USER>@<IP_VPS>:/tmp/src-update
scp -i <CHEMIN_CLE_SSH> server/package.json <USER>@<IP_VPS>:/tmp/package.json

# Sur le VPS :
sudo cp -r /tmp/src-public/* /opt/hockey-club-server/public/
sudo cp -r /tmp/src-update/* /opt/hockey-club-server/src/
sudo cp /tmp/package.json /opt/hockey-club-server/package.json
sudo chown -R hockey:hockey /opt/hockey-club-server/src /opt/hockey-club-server/public /opt/hockey-club-server/package.json
cd /opt/hockey-club-server && sudo -u hockey npm install && sudo -u hockey npm run build
sudo systemctl restart hockey-club-server
```

**Vérification après coup** :

```bash
grep -c "un_bout_de_code_que_tu_viens_de_changer" /opt/hockey-club-server/dist/nom_du_fichier.js
```

Un `0` veut dire que le transfert ou le build n'a pas pris ton changement en compte.

## Surveiller les logs

```bash
sudo journalctl -u hockey-club-server -f
```

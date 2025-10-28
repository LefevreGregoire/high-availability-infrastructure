# TP DashOps - SN2 EPSI 2025 - Grégoire LEFEVRE 

# Mise en place du protocole STP avec Cisco Packet Tracer

Cette partie du TP concerne la configuration et la validation du protocole Spanning Tree Protocol (STP) sur une topologie réseau redondante composée de trois switches interconnectés et de deux ordinateurs.

## Architecture

La topologie du réseau à mettre en place se compose de :

- **Switch2** : Switch primaire (Root Bridge)
- **Switch0** : Switch secondaire
- **Switch1** : Switch secondaire
- **PC0** : Connecté au Switch0
- **PC1** : Connecté au Switch1

Les trois switches sont interconnectés de manière redondante, formant une **topologie en triangle**. Cette configuration crée plusieurs chemins possibles entre les switches, ce qui pourrait normalement provoquer une boucle de trames Ethernet. Grâce au STP, un des ports sera automatiquement mis en état bloqué, assurant une topologie logique sans boucle tout en maintenant une liaison de secours en cas de panne.

![[triangle.png]]

## Prérequis

- **Logiciel** : Cisco Packet Tracer
- **Équipements** : 3 switches Cisco 2960-24TT, 2 PC
- **Connaissances** : Protocole STP, commandes Cisco IOS

## Configuration de la topologie

### Étape 1 : Création de la topologie physique

Dans Cisco Packet Tracer, créer la topologie suivante :

```bash
# Équipements à placer :
- 3 x Switch Cisco 2960-24TT (Switch0, Switch1, Switch2)
- 2 x PC (PC0, PC1)

# Connexions entre switches (topologie triangulaire) :
- Switch2 <---> Switch0 (FastEthernet0/2 <---> FastEthernet0/3)
- Switch2 <---> Switch1 (FastEthernet0/4 <---> FastEthernet0/3)
- Switch0 <---> Switch1 (FastEthernet0/1 <---> FastEthernet0/1)

# Connexions PC vers switches :
- PC0 <---> Switch0 (FastEthernet0/1)
- PC1 <---> Switch1 (FastEthernet0/4)
```

### Étape 2 : Configuration IP des PC

#### Configuration de PC0

```bash
IP Address: 192.168.1.1
Subnet Mask: 255.255.255.0
Default Gateway: 192.168.1.254
```

#### Configuration de PC1

```bash
IP Address: 192.168.1.2
Subnet Mask: 255.255.255.0
Default Gateway: 192.168.1.254
```

### Étape 3 : Configuration du Switch primaire (Switch2)

Accéder au CLI de **Switch2** et le configurer comme Root Bridge :

```bash
Switch>enable
Switch#configure terminal
Switch(config)#hostname Switch2
Switch2(config)#spanning-tree vlan 1 root primary
Switch2(config)#exit
Switch2#write memory
```

### Étape 4 : Configuration des switches secondaires

Sur **Switch0** et **Switch1**, aucune configuration particulière n'est nécessaire. STP s'activera automatiquement.

```bash
Switch>enable
Switch#configure terminal
Switch(config)#hostname Switch0  # ou Switch1
Switch0(config)#exit
Switch0#write memory
```

## Step 1 : Validation du bon fonctionnement de STP

### Vérification de l'état du Spanning Tree

Sur chaque switch, vérifier l'état du protocole STP :

```bash
Switch#show spanning-tree
```

![[CLI-switches.png]]

### Analyse de Switch2 (Root Bridge)

**Observations** :

- **Root ID Priority** : 24577
- **Bridge ID** : `0000.0CA6.15B3` - **This bridge is the root**
- **Tous les ports en état Designated (Desg)** : Le Root Bridge a tous ses ports en mode forwarding
- Interfaces actives :
    - `Fa0/2` : Desg FWD (vers Switch0)
    - `Fa0/4` : Desg FWD (vers Switch1)

### Analyse de Switch0 (Switch secondaire)

**Observations** :

- **Root ID Priority** : 24577
- **Bridge ID Priority** : 28673 (plus élevé que le root)
- **Rôles des ports** :
    - `Fa0/1` : Desg FWD (vers PC0 et Switch1)
    - `Fa0/2` : Root FWD (chemin vers le Root Bridge)
    - `Fa0/3` : Altn BLK ⚠️ **Port bloqué** (lien redondant)

Le port `Fa0/3` est en état **Alternate Blocking** pour éviter les boucles.

### Analyse de Switch1 (Switch secondaire)

**Observations** :

- **Root ID Priority** : 24577
- **Bridge ID Priority** : 28673
- **Rôles des ports** :
    - `Fa0/1` : Desg FWD (vers PC1)
    - `Fa0/3` : Desg FWD (vers Switch2)
    - `Fa0/4` : Root FWD (chemin vers le Root Bridge)

### Test de connectivité

Vérifier la communication entre les PC :

```bash
# Depuis PC1
C:\>ping 192.168.1.1
```

![[ping-cisco.png]]
## Step 2 : Test de basculement (Failover)

Cette étape démontre la capacité de STP à reconfigurer automatiquement la topologie en cas de panne du switch primaire. 

### Simulation de la panne du Root Bridge

Pour simuler la panne de Switch2, l'éteindre dans Packet Tracer :

1. Cliquer sur **Switch2**
2. Sélectionner l'onglet **Physical**
3. Éteindre le switch (bouton Power)

### Observation de la reconfiguration STP

Attendre quelques secondes (convergence STP : ~30-50 secondes) puis vérifier l'état sur les switches restants.

#### Sur Switch1 (après panne de Switch2)

```bash
Switch1#show spanning-tree
```

**Observations** :

- **Root ID** : Switch1 devient le nouveau **Root Bridge**
- **Bridge ID Priority** : 28673 - **This bridge is the root**
- Tous les ports passent en état **Designated Forwarding**
- Le réseau se reconfigure automatiquement

#### Sur Switch0 (après panne de Switch2)

```bash
Switch0#show spanning-tree
```

**Observations** :

- **Root ID** : Pointe maintenant vers Switch1
- Le port `Fa0/3` qui était bloqué passe en état **Root FWD**
- La topologie converge vers le nouveau Root Bridge

### Test de connectivité après basculement

Vérifier que la communication fonctionne toujours :

```bash
# Depuis PC0
C:\>ping 192.168.1.2
```

**Résultat** : La communication est maintenue malgré la panne du switch primaire !

## Tableau récapitulatif de la configuration STP

|Élément|Switch2 (Root)|Switch0|Switch1|
|---|---|---|---|
|**Rôle STP**|Root Bridge|Secondary|Secondary|
|**Bridge Priority**|24577|28673|28673|
|**Bridge ID**|0000.0CA6.15B3|0090.0CD0.E9B7|0001.43C6.CC91|
|**État des ports**|Tous Desg FWD|Fa0/1: Desg FWD<br>Fa0/2: Root FWD<br>Fa0/3: Altn BLK|Fa0/1: Desg FWD<br>Fa0/3: Desg FWD<br>Fa0/4: Root FWD|
|**PC connecté**|Aucun|PC0 (192.168.1.1)|PC1 (192.168.1.2)|

## Commandes utiles pour la validation

```bash
# Afficher l'état du spanning-tree
show spanning-tree

# Afficher l'état détaillé du spanning-tree pour VLAN 1
show spanning-tree vlan 1

# Afficher uniquement le résumé
show spanning-tree summary

# Configurer manuellement la priorité
spanning-tree vlan 1 priority <valeur>

# Définir un switch comme root primaire
spanning-tree vlan 1 root primary

# Définir un switch comme root secondaire
spanning-tree vlan 1 root secondary
```
# Installation et configuration des routeurs R1 et R2

Cette partie du TP concerne la mise en place de deux routeurs Alpine Linux avec une architecture résiliente basée sur UCARP pour la gestion de l'IP virtuelle (VIP) et assurant le routage NAT pour l'ensemble de l'infrastructure.

## Architecture

- **R1** : Routeur principal (192.168.1.252)
- **R2** : Routeur secondaire (192.168.1.253)
- **VIP Routeurs** : Adresse IP virtuelle partagée entre les deux routeurs

## Prérequis

Les deux routeurs doivent avoir :

- **Interface eth0** : Réseau NAT (accès Internet via VirtualBox)
- **Interface eth1** : Réseau Interne (192.168.1.0/24)
- **Système d'exploitation** : Alpine Linux

## Configuration réseau statique sur R1 :

Éditer le fichier `/etc/network/interfaces` :

```bash
sudo nano /etc/network/interfaces
```

Ajouter la configuration suivante :

```bash
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 192.168.1.252
    netmask 255.255.255.0
```

## Configuration réseau statique sur R2 :

```bash
sudo nano /etc/network/interfaces
```

```bash
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 192.168.1.253
    netmask 255.255.255.0
```

![[IPRouters.png]]

Redémarrer le service réseau sur les deux machines :

```bash
rc-service networking restart
```

Vérifier la configuration :

```bash
ip a
```

![[IP-a routers + VIP.png]]
## Configuration du routage et NAT

### Activation du forwarding IP

Sur **R1** et **R2** :

```bash
# Activer le forwarding IP temporairement
echo 1 > /proc/sys/net/ipv4/ip_forward

# Rendre permanent au redémarrage
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
```

### Configuration des règles iptables

Sur **R1** et **R2**, créer le script de configuration iptables :

```bash
nano /etc/local.d/firewall.start
```

Contenu du script :

```bash
#!/bin/sh

# Vider les règles existantes
iptables -F
iptables -t nat -F

# Autoriser le trafic sur loopback
iptables -A INPUT -i lo -j ACCEPT

# Autoriser les connexions établies et liées
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Autoriser SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Autoriser VRRP (UCARP)
iptables -A INPUT -p vrrp -j ACCEPT

# Configuration NAT (masquerading)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Autoriser le forwarding pour le réseau interne
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Politique par défaut
iptables -P INPUT DROP
iptables -P FORWARD DROP
```

Donner les permissions d'exécution :

```bash
chmod +x /etc/local.d/firewall.start
```

Activer le service local pour qu'il se lance au démarrage :

```bash
rc-update add local default
```

Appliquer immédiatement les règles :

```bash
/etc/local.d/firewall.start
```

Vérifier les règles iptables :

```bash
iptables -L -v -n
iptables -t nat -L -v -n
```

## Mise en place d'une VIP via UCARP

### Installation de UCARP

Sur **R1** et **R2** :

```bash
apk update
apk add ucarp
```

### Configuration de UCARP sur R1 (MASTER)

Éditer le fichier de configuration :

```bash
sudo nano /etc/conf.d/ucarp
```

Configuration pour R1 :

```bash
# Configuration UCARP pour R1 (MASTER)
UCARP_INTERFACE="eth1"
UCARP_VIP="192.168.1.254"
UCARP_PASSWORD="router_ha"
UCARP_VHID="1"
UCARP_ADVSKEW="1"
UCARP_ADVBASE="1"
UCARP_OPTS="--shutdown"
```

### Configuration de UCARP sur R2 (BACKUP)

```bash
sudo nano /etc/conf.d/ucarp
```

Configuration pour R2 :

```bash
# Configuration UCARP pour R2 (BACKUP)
UCARP_INTERFACE="eth1"
UCARP_VIP="192.168.1.254"
UCARP_PASSWORD="router_ha"
UCARP_VHID="1"
UCARP_ADVSKEW="10"
UCARP_ADVBASE="1"
UCARP_OPTS="--shutdown"
```

**Note** : Le paramètre `UCARP_ADVSKEW` détermine la priorité. Une valeur plus faible = priorité plus élevée.

![[Screenshot From 2025-10-25 22-08-30.png]]
### Démarrage de UCARP

Sur **R1** et **R2** :

```bash
# Activer UCARP au démarrage
rc-update add ucarp

# Démarrer UCARP
rc-service ucarp start

# Vérifier le statut
rc-service ucarp status
```

![[Screenshot From 2025-10-25 22-04-48.png]]

Si un routeur tombe en panne, le second prend automatiquement le relais en récupérant la VIP, assurant ainsi une continuité de service sans intervention manuelle.

## Tableau récapitulatif de la configuration

| Élément                        | R1                   | R2                   |
| ------------------------------ | -------------------- | -------------------- |
| **Système**                    | Alpine Linux         | Alpine Linux         |
| **Interface eth0**             | DHCP (NAT)           | DHCP (NAT)           |
| **Interface eth1**             | 192.168.1.252        | 192.168.1.253        |
| **Rôle UCARP**                 | MASTER               | BACKUP               |
| **Priorité UCARP (advskew)**   | 1                    | 10                   |
| **VIP (partagée)**             | 192.168.1.254        | 192.168.1.254        |
| **Virtual Host ID**            | 1                    | 1                    |
| **Méthode d'authentification** | PASSWORD (router_ha) | PASSWORD (router_ha) |
| **NAT**                        | ✅ Actif              | ✅ Actif              |
| **IP Forwarding**              | ✅ Activé             | ✅ Activé             |
# Installation et configuration des reverse Proxies NGINX

Cette partie du TP concerne la mise en place de deux serveurs reverse proxy NGINX avec une architecture résiliente basée sur Keepalived pour la gestion de l'IP virtuelle (VIP) et assurant la distribution de charge vers les serveurs frontend et backend.

## Architecture

- **NGINX01** : Reverse proxy principal (192.168.1.100)
- **NGINX02** : Reverse proxy secondaire (192.168.1.101)
- **VIP NGINX** : Adresse IP virtuelle partagée (192.168.1.150/24)
- **Système** : Debian 12.4

## Prérequis

Les deux serveurs NGINX doivent avoir :

- **Interface réseau** : Réseau Interne
- **Accès au réseau interne** : 192.168.1.0/24
- **Gateway** : 192.168.1.252 (NGINX01) ou 192.168.1.253 (NGINX02)

## Configuration réseau statique sur NGINX01

Éditez le fichier `/etc/network/interfaces` :

```bash
sudo nano /etc/network/interfaces
```

Ajoutez la configuration suivante :

```bash
# Interface réseau principale
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.252
    dns-nameservers 8.8.8.8 8.8.4.4
```

## Sur NGINX02

```bash
sudo nano /etc/network/interfaces

# Interface réseau principale
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.101
    netmask 255.255.255.0
    gateway 192.168.1.253
    dns-nameservers 8.8.8.8 8.8.4.4
```

Redémarrez le service réseau sur les deux machines :

```bash
sudo systemctl restart networking
```

Vérifiez la configuration :

```bash
ip a
```

## Installation des paquets nécessaires

Sur **NGINX01** et **NGINX02**, installez les paquets requis :

```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation de NGINX
sudo apt install -y nginx

# Installation de Keepalived pour la haute disponibilité
sudo apt install -y keepalived

# Installation de PHP et extensions pour le serveur frontend
sudo apt install -y php8.2 php8.2-cli php8.2-fpm php8.2-common php8.2-curl \
                     php8.2-mbstring php8.2-xml php8.2-zip

# Installation de Git et Composer
sudo apt install -y git curl unzip

# Installation de Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

# Vérification des installations
nginx -v
php --version
composer --version
```

## Récupération du projet Frontend

Sur **NGINX01** et **NGINX02**, clonez le dépôt frontend :

```bash
# Se positionner dans le répertoire web
cd /var/www/html

# Supprimer le contenu par défaut
sudo rm -rf *

# Cloner le projet frontend depuis GitHub
sudo git clone https://github.com/ClemLcs/ManageVMFront.git .

# Installer les dépendances PHP
sudo composer install --no-dev --optimize-autoloader

# Donner les permissions appropriées
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

## Configuration de NGINX

### Suppression de la configuration par défaut

Sur **NGINX01** et **NGINX02** :

```bash
# Supprimer le fichier de configuration par défaut
sudo rm /etc/nginx/sites-enabled/default
```

### Création de la configuration reverse proxy

Créez le fichier de configuration :

```bash
sudo nano /etc/nginx/sites-available/reverse-proxy
```

Contenu de la configuration :

```bash
# Définition des serveurs backend
upstream backend_servers {
    least_conn;  # Équilibrage basé sur le nombre de connexions actives
    server 192.168.1.200:8000;  # VIP Backend (Keepalived BACKEND01/02)
}

# Définition des serveurs frontend (instances PHP locales)
upstream frontend_servers {
    least_conn;
    server 127.0.0.1:8001;  # Instance PHP locale sur NGINX01 (ou 8002 sur NGINX02)
}

server {
    listen 80;
    server_name _;

    # Logs
    access_log /var/log/nginx/reverse-proxy-access.log;
    error_log /var/log/nginx/reverse-proxy-error.log;

    # Routage vers le frontend
    location / {
        proxy_pass http://frontend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Routage vers le backend API
    location /api/v1/ {
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Activation de la configuration

```bash
# Créer le lien symbolique
sudo ln -s /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/

# Tester la configuration
sudo nginx -t

# Recharger NGINX
sudo systemctl reload nginx

# Vérifier le statut
sudo systemctl status nginx
```

## Configuration du service PHP Frontend

Pour garantir la haute disponibilité du serveur PHP frontend, créez un service systemd qui le gérera automatiquement.

### Sur NGINX01

Créez le fichier de service :

```bash
sudo nano /etc/systemd/system/front-local.service
```

Contenu du fichier pour NGINX01 :

INI

```bash
[Unit]
Description=Frontend PHP Server on port 8001
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/html
ExecStart=/usr/bin/php -S 127.0.0.1:8001 -t public
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Sur NGINX02

Créez le fichier de service :

```bash
sudo nano /etc/systemd/system/front-local.service
```

Contenu du fichier pour NGINX02 (port différent) :

INI

```bash
[Unit]
Description=Frontend PHP Server on port 8002
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/html
ExecStart=/usr/bin/php -S 127.0.0.1:8002 -t public
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Activation du service

Sur **NGINX01** et **NGINX02** :

```bash
# Recharger la configuration systemd
sudo systemctl daemon-reload

# Activer le service au démarrage
sudo systemctl enable front-local.service

# Démarrer le service
sudo systemctl start front-local.service

# Vérifier le statut
sudo systemctl status front-local.service
```

**Note** : Ne pas oublier de modifier l'upstream `frontend_servers` dans la configuration NGINX02 pour pointer vers le port 8002 :

Nginx

```bash
upstream frontend_servers {
    least_conn;
    server 127.0.0.1:8002;  # Port 8002 sur NGINX02
}
```

## Mise en place de la VIP via Keepalived

### Script de vérification de service

Créez un script qui vérifiera si NGINX et le service PHP sont actifs :

```bash
sudo nano /usr/local/bin/check_nginx_service.sh
```

Contenu du script :

```bash
#!/bin/bash
# Script de vérification des services NGINX et PHP Frontend

# Vérifier si NGINX est actif
if ! systemctl is-active --quiet nginx; then
    exit 1
fi

# Vérifier si le service PHP frontend est actif
if ! systemctl is-active --quiet front-local.service; then
    exit 1
fi

# Vérifier si NGINX répond sur le port 80
if ! curl -sf http://localhost:80 > /dev/null 2>&1; then
    exit 1
fi

exit 0
```

Donnez les permissions d'exécution :

```bash
sudo chmod +x /usr/local/bin/check_nginx_service.sh
```

### Configuration de Keepalived sur NGINX01 (MASTER)

Éditez le fichier de configuration :

```bash
sudo nano /etc/keepalived/keepalived.conf
```

Configuration pour NGINX01 :

```bash
vrrp_script chk_nginx {
    script "/usr/local/bin/check_nginx_service.sh"
    interval 2
    timeout 2
    fall 2
    rise 2
}

vrrp_instance VI_NGINX {
    state MASTER
    interface enp0s3
    virtual_router_id 50
    priority 110
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass nginx_ha
    }

    virtual_ipaddress {
        192.168.1.150/24
    }

    track_script {
        chk_nginx
    }
}
```

### Configuration de Keepalived sur NGINX02 (BACKUP)

```bash
sudo nano /etc/keepalived/keepalived.conf
```

Configuration pour NGINX02 :

```bash
vrrp_script chk_nginx {
    script "/usr/local/bin/check_nginx_service.sh"
    interval 2
    timeout 2
    fall 2
    rise 2
}

vrrp_instance VI_NGINX {
    state BACKUP
    interface enp0s3
    virtual_router_id 50
    priority 100
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass nginx_ha
    }

    virtual_ipaddress {
        192.168.1.150/24
    }

    track_script {
        chk_nginx
    }
}
```

### Démarrage de Keepalived

Sur **NGINX01** et **NGINX02** :

```bash
# Activer Keepalived au démarrage
sudo systemctl enable keepalived

# Démarrer Keepalived
sudo systemctl start keepalived

# Vérifier le statut
sudo systemctl status keepalived
```

Si un serveur NGINX tombe en panne, le second prend automatiquement le relais en récupérant la VIP, assurant ainsi une continuité de service sans interruption.

## Configuration du Firewall

Pour sécuriser les serveurs reverse proxy, configurez le firewall UFW.

### Installation et configuration sur NGINX01 et NGINX02

```bash
# Installation de UFW
sudo apt install -y ufw

# Configuration des règles de base
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Autoriser SSH (important pour ne pas perdre l'accès)
sudo ufw allow 22/tcp

# Autoriser HTTP (port 80 pour le reverse proxy)
sudo ufw allow 80/tcp

# Autoriser HTTPS (si SSL configuré)
sudo ufw allow 443/tcp

# Autoriser le protocole VRRP pour Keepalived
sudo ufw allow proto vrrp

# Autoriser la communication entre les serveurs NGINX
sudo ufw allow from 192.168.1.100
sudo ufw allow from 192.168.1.101

# Autoriser les routeurs à communiquer avec NGINX
sudo ufw allow from 192.168.1.252
sudo ufw allow from 192.168.1.253

# Activer le firewall
sudo ufw enable

# Vérifier les règles
sudo ufw status verbose
```

## Tests et Validation

### Test du serveur NGINX en local

Vérifiez que NGINX répond correctement :

```bash
# Test en local
curl -I http://localhost

# Test via la VIP (depuis une autre machine du réseau)
curl -I http://192.168.1.150
```

### Test de la haute disponibilité

#### Étape 1 : Vérifier l'état initial

```bash
# Sur NGINX01 - La VIP doit être présente
ip a show enp0s3 | grep 192.168.1.150
```

#### Étape 2 : Simuler une panne

```bash
# Sur NGINX01 - Arrêter NGINX
sudo systemctl stop nginx
```

Ou arrêter Keepalived directement :

```bash
# Sur NGINX01
sudo systemctl stop keepalived
```

#### Étape 3 : Vérifier le basculement

```bash
# Sur NGINX02 (attendre 2-3 secondes)
ip a show enp0s3 | grep 192.168.1.150
```

La VIP devrait maintenant être visible sur NGINX02.

#### Étape 4 : Tester l'accès au service

Depuis une machine cliente du réseau :

```bash
# Le service doit rester accessible via la VIP
curl http://192.168.1.150

# Tester l'API backend
curl http://192.168.1.150/api/v1/vms
```

#### Étape 5 : Restaurer le service

```bash
# Sur NGINX01
sudo systemctl start nginx
sudo systemctl start keepalived
```

Après quelques secondes, la VIP devrait revenir sur NGINX01 (priorité plus élevée : 110 > 100).

### Vérification des logs

```bash
# Logs NGINX
sudo tail -f /var/log/nginx/reverse-proxy-access.log
sudo tail -f /var/log/nginx/reverse-proxy-error.log

# Logs Keepalived
sudo journalctl -u keepalived -f

# Logs du service PHP frontend
sudo journalctl -u front-local.service -f
```

## Tableau récapitulatif de la configuration

| Élément                        | NGINX01                               | NGINX02                               |
| ------------------------------ | ------------------------------------- | ------------------------------------- |
| **IP statique**                | 192.168.1.100                         | 192.168.1.101                         |
| **Gateway**                    | 192.168.1.252                         | 192.168.1.253                         |
| **Rôle Keepalived**            | MASTER                                | BACKUP                                |
| **Priorité VRRP**              | 110                                   | 100                                   |
| **VIP (partagée)**             | 192.168.1.150/24                      | 192.168.1.150/24                      |
| **Virtual Router ID**          | 50                                    | 50                                    |
| **Port NGINX**                 | 80                                    | 80                                    |
| **Port PHP Frontend**          | 8001                                  | 8002                                  |
| **Méthode d'authentification** | PASS (nginx_ha)                       | PASS (nginx_ha)                       |
| **Script de vérification**     | /usr/local/bin/check_nginx_service.sh | /usr/local/bin/check_nginx_service.sh |
| **Backend upstream**           | 192.168.1.200:8000 (VIP Backend)      | 192.168.1.200:8000 (VIP Backend)      |
# Installation et Configuration des serveurs Backend

Cette partie du TP concerne la mise en place de deux serveurs backend avec une architecture résiliente basée sur Keepalived pour la gestion de l'IP virtuelle (VIP).

Architecture

    BACKEND01 : Serveur backend principal (192.168.1.250)
    BACKEND02 : Serveur backend secondaire (192.168.1.251)
    VIP Backend : Adresse IP virtuelle partagée (192.168.1.200/24)

Prérequis

Les deux serveurs backend doivent avoir :

    Interface réseau : Réseau Interne
    Accès au réseau interne : 192.168.1.0/24
    Gateway : 192.168.1.252 (BACKEND01) ou 192.168.1.253 (BACKEND02)

#### Configuration réseau statique sur BACKEND01

Éditer le fichier /etc/network/interfaces :

```bash
sudo nano /etc/network/interfaces
```

Ajouter la configuration suivante :

```bash
# Interface réseau principale
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.250
    netmask 255.255.255.0
    gateway 192.168.1.252
    dns-nameservers 8.8.8.8 8.8.4.4
```

#### Sur BACKEND02

```bash
sudo nano /etc/network/interfaces

# Interface réseau principale
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.251
    netmask 255.255.255.0
    gateway 192.168.1.253
    dns-nameservers 8.8.8.8 8.8.4.4
```

![[adressage backends.png]]
Redémarrer le service réseau sur les deux machines :

```bash
sudo systemctl restart networking
```

Vérifier la configuration :

```bash
ip a
```

![[ip-a-Back.png]]
#### Installation des serveurs Backend

Étape 1 : Installation des dépendances

Sur **BACKEND01** et **BACKEND02**, installer les paquets nécessaires :

```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation de PHP 8.2 et extensions requises
sudo apt install -y php8.2 php8.2-cli php8.2-common php8.2-curl php8.2-mbstring \
                     php8.2-xml php8.2-zip php8.2-intl git curl unzip

# Installation de Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

# Vérification de l'installation
php --version
composer --version
```

Étape 2 : Clonage et configuration du projet

Sur les deux serveurs :

```bash

# Se positionner dans le répertoire approprié
cd /opt

# Cloner le dépôt GitHub
sudo git clone https://github.com/ClemLcs/ManageVMBack.git
cd ManageVMBack

# Donner les permissions appropriées
sudo chown -R www-data:www-data /opt/ManageVMBack
sudo chmod -R 755 /opt/ManageVMBack
```

Étape 3 : Installation des dépendances PHP
```bash
cd /opt/ManageVMBack

# Installation des dépendances avec Composer
sudo -u www-data composer install --no-dev --optimize-autoloader

# Vider le cache Symfony
sudo -u www-data php bin/console cache:clear
```

## Mise en place d'une VIP via keepalived

Dans le fichier /usr/local/bin/check_service.sh :

```bash
if systemctl is-active --quiet managevmback.service; then
    exit 0
else
    exit 1
fi
```

Donner les permissions d'exécution :

```bash
sudo chmod +x /usr/local/bin/check_service.sh
```

#### Configuration de Keepalived sur BACKEND01 (MASTER)

Éditer le fichier de configuration :

```bash
sudo nano /etc/keepalived/keepalived.conf
```

Configuration pour BACKEND01 :

```bash
vrrp_script chk_service {
    script "/usr/local/bin/check_service.sh"
    interval 2
    timeout 2
    fall 2
    rise 2
}

vrrp_instance VI_BACKEND {
    state MASTER
    interface enp0s3
    virtual_router_id 60
    priority 110
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass backend_ha
    }

    virtual_ipaddress {
        192.168.1.200/24
    }

    track_script {
        chk_service
    }
}
```
#### Configuration de Keepalived sur BACKEND02 (BACKUP)
```bash
sudo nano /etc/keepalived/keepalived.conf
```

Configuration pour BACKEND02 :
```bash
vrrp_script chk_service {
    script "/usr/local/bin/check_service.sh"
    interval 2
    timeout 2
    fall 2
    rise 2
}

vrrp_instance VI_BACKEND {
    state BACKUP
    interface enp0s3
    virtual_router_id 60
    priority 100
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass backend_ha
    }

    virtual_ipaddress {
        192.168.1.200/24
    }

    track_script {
        chk_service
    }
}
```

![[VIP-backs.png]]

Démarrage de Keepalived sur les deux serveurs :

```bash
# Activer Keepalived au démarrage
sudo systemctl enable keepalived

# Démarrer Keepalived
sudo systemctl start keepalived

# Vérifier le statut
sudo systemctl status keepalived
```

![[Screenshot From 2025-10-25 21-38-25.png]]

Si un serveur backend tombe en panne, le second prend automatiquement le relais en récupérant la VIP, assurant ainsi une continuité de service sans intervention manuelle.

## Configuration du Service Systemd

Pour garantir la haute disponibilité, créez un service systemd qui relancera automatiquement le serveur backend en cas de panne.

### Création du service

Sur **BACKEND01** et **BACKEND02**, créer le fichier de service :

```bash
sudo nano /etc/systemd/system/managevmback.service
```

Contenu du fichier :

```ini
[Unit]
Description=ManageVMBack API Service
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/ManageVMBack
ExecStart=/usr/bin/php -S 0.0.0.0:8000 -t /opt/ManageVMBack/public
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Activation du service

```bash
# Recharger la configuration systemd
sudo systemctl daemon-reload

# Activer le service au démarrage
sudo systemctl enable managevmback.service

# Démarrer le service
sudo systemctl start managevmback.service

# Vérifier le statut
sudo systemctl status managevmback.service
```

## Configuration du Firewall

Pour sécuriser les serveurs backend, configurer le firewall UFW.
Installation et configuration sur BACKEND01 et BACKEND02

```bash
# Installation de UFW
sudo apt install -y ufw

# Configuration des règles de base
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Autoriser SSH (important pour ne pas perdre l'accès)
sudo ufw allow 22/tcp

# Autoriser le port de l'API backend (8000)
sudo ufw allow 8000/tcp

# Autoriser le protocole VRRP pour Keepalived
sudo ufw allow proto vrrp

# Autoriser la communication entre les serveurs backend
sudo ufw allow from 192.168.1.250
sudo ufw allow from 192.168.1.251

# Autoriser les serveurs NGINX à communiquer avec les backends
sudo ufw allow from 192.168.1.0/24 to any port 8000

# Activer le firewall
sudo ufw enable

# Vérifier les règles
sudo ufw status verbose
```

![[Screenshot From 2025-10-25 21-40-34.png]]

## Tableau récapitulatif de la configuration

| Élément | BACKEND01 | BACKEND02 |
|---------|-----------|-----------|
| **IP statique** | 192.168.1.250 | 192.168.1.251 |
| **Gateway** | 192.168.1.252 | 192.168.1.253 |
| **Rôle Keepalived** | MASTER | BACKUP |
| **Priorité VRRP** | 110 | 100 |
| **VIP (partagée)** | 192.168.1.200/24 | 192.168.1.200/24 |
| **Virtual Router ID** | 60 | 60 |
| **Port API** | 8000 | 8000 |
| **Méthode d'authentification** | PASS (backend_ha) | PASS (backend_ha) |
| **Script de vérification** | /usr/local/bin/check_service.sh | /usr/local/bin/check_service.sh |
	

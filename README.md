# Infrastructure Réseau Haute Disponibilité

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Debian](https://img.shields.io/badge/Debian-12.4-red.svg)](https://www.debian.org/)
[![Alpine Linux](https://img.shields.io/badge/Alpine-3.x-0D597F.svg)](https://alpinelinux.org/)
[![NGINX](https://img.shields.io/badge/NGINX-1.22-009639.svg)](https://nginx.org/)

Implémentation complète d'une infrastructure réseau hautement disponible avec basculement automatique, comprenant des routeurs redondants, des équilibreurs de charge et des serveurs backend.

---

## À propos

Ce projet présente la conception et l'implémentation d'une infrastructure réseau résiliente de niveau entreprise avec plusieurs niveaux de redondance. L'architecture garantit une disponibilité continue du service grâce à des mécanismes de basculement automatisés aux couches routage, équilibrage de charge et application.

**Objectifs principaux :**

- Temps d'arrêt nul lors de pannes de composants
- Basculement automatique avec adresses IP virtuelles basées sur VRRP
- Distribution de charge entre plusieurs serveurs
- Prévention des boucles réseau avec Spanning Tree Protocol
- Communications sécurisées avec règles de pare-feu

---

## Documentation

La documentation technique complète est disponible dans **[DOCUMENTATION.md](DOCUMENTATION.md)** et couvre :

1. **Protocole Spanning Tree (STP)** avec Cisco Packet Tracer
   - Configuration de la topologie redondante en triangle
   - Élection du Root Bridge et blocage de ports
   - Tests de basculement automatique

2. **Routeurs redondants** avec Alpine Linux et UCARP
   - Configuration réseau et NAT avec iptables
   - Mise en place de l'IP virtuelle avec UCARP
   - Haute disponibilité du routage

3. **Reverse Proxy et équilibreur de charge** avec NGINX et Keepalived
   - Configuration NGINX pour distribution de charge
   - Keepalived pour VIP et basculement automatique
   - Routage intelligent vers frontend et backend

4. **Serveurs Backend** avec Debian, PHP et Keepalived
   - Déploiement de l'API REST
   - Haute disponibilité avec Keepalived
   - Configuration firewall UFW

---

## Architecture

```
                    Internet
                        │
                [Passerelle NAT]
                        │
    ┌───────────────────┴───────────────────┐
    │                                       │
[Routeur 1]                           [Routeur 2]
192.168.1.252                        192.168.1.253
    │                                       │
    └──────────[VIP: 192.168.1.254]────────┘
                        │
              [Réseau Interne 192.168.1.0/24]
                        │
    ┌───────────────────┴───────────────────┐
    │                                       │
[Équilibreur 1]                      [Équilibreur 2]
192.168.1.100                        192.168.1.101
    │                                       │
    └──────────[VIP: 192.168.1.150]────────┘
                        │
    ┌───────────────────┴───────────────────┐
    │                                       │
[Serveur Backend 1]                  [Serveur Backend 2]
192.168.1.250                        192.168.1.251
    │                                       │
    └──────────[VIP: 192.168.1.200]────────┘
```

---

## Technologies utilisées

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| **Switches réseau** | Cisco 2960-24TT | Commutation Layer 2 avec STP |
| **Routeurs** | Alpine Linux 3.x + UCARP | NAT et routage avec HA |
| **Équilibreurs de charge** | NGINX 1.22 + Keepalived 2.2 | Reverse proxy et distribution |
| **Serveurs Backend** | Debian 12.4 + PHP 8.2 + Keepalived | API REST haute disponibilité |
| **Pare-feu** | UFW (iptables) | Sécurité réseau |
| **Virtualisation** | VirtualBox 7.x | Infrastructure virtuelle |

---

## Démarrage rapide

### Prérequis

- VirtualBox 7.x ou supérieur
- Cisco Packet Tracer 8.x
- Connaissances de base en administration système Linux

### Cloner le dépôt

```bash
git clone https://github.com/LefevreGregoire/high-availability-infrastructure.git
cd high-availability-infrastructure
```

### Déployer l'infrastructure

Suivez la documentation complète dans DOCUMENTATION.md dans l'ordre :

1. Configuration de la topologie STP
2. Déploiement des routeurs R1 et R2
3. Configuration des équilibreurs de charge NGINX
4. Mise en place des serveurs backend

### Plan d'adressage IP

| Équipement | Interface | Adresse IP | Passerelle | IP Virtuelle (VIP) |
|------------|-----------|------------|------------|--------------------|
| Routeur 1 | eth0 | DHCP | - | - |
| Routeur 1 | eth1 | 192.168.1.252 | - | 192.168.1.254 |
| Routeur 2 | eth0 | DHCP | - | - |
| Routeur 2 | eth1 | 192.168.1.253 | - | 192.168.1.254 |
| Équilibreur 1 | enp0s3 | 192.168.1.100 | 192.168.1.252 | 192.168.1.150 |
| Équilibreur 2 | enp0s3 | 192.168.1.101 | 192.168.1.253 | 192.168.1.150 |
| Backend 1 | enp0s3 | 192.168.1.250 | 192.168.1.252 | 192.168.1.200 |
| Backend 2 | enp0s3 | 192.168.1.251 | 192.168.1.253 | 192.168.1.200 |

### Structure du projet

```
high-availability-infrastructure/
├── README.md                      # Vue d'ensemble
├── DOCUMENTATION.md               # Documentation technique complète
├── LICENSE                        # Licence MIT
├── docs/
│   └── images/                    # Captures d'écran
├── configs/
│   ├── nginx/                     # Configurations NGINX
│   ├── keepalived/                # Configurations Keepalived
│   ├── ucarp/                     # Configurations UCARP
│   ├── systemd/                   # Services systemd
│   └── scripts/                   # Scripts de vérification
└── network-diagrams/
    └── packet-tracer-topology.pkt # Topologie Packet Tracer
```

---

## Tests de validation

### Test de basculement des routeurs

```bash
# Sur Routeur 1
ssh root@192.168.1.252
rc-service ucarp stop
# Vérifier que la VIP 192.168.1.254 bascule vers Routeur 2
```

### Test de basculement de l'équilibreur

```bash
# Sur Équilibreur 1
ssh user@192.168.1.100
sudo systemctl stop keepalived
# Vérifier que la VIP 192.168.1.150 bascule vers Équilibreur 2
```

### Test de basculement du backend

```bash
# Sur Backend 1
ssh user@192.168.1.250
sudo systemctl stop keepalived
# Vérifier que la VIP 192.168.1.200 bascule vers Backend 2
```

---

## Caractéristiques de performance

- **Temps de basculement (Routeur)** : < 3 secondes
- **Temps de basculement (Équilibreur)** : < 2 secondes
- **Temps de basculement (Backend)** : < 2 secondes
- **Convergence STP** : 30-50 secondes
- **Connexions simultanées supportées** : 1000+ (configurable)

---

## Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## Auteur

**Grégoire LEFEVRE** - EPSI SN2 2025


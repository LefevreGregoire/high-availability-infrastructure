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

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

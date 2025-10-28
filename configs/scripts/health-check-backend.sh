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

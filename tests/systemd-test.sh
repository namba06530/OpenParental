#!/bin/bash
set -euo pipefail

# Variables de couleur pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Test des services systemd pour le quota internet ===${NC}"

# Construction de l'image Docker
echo -e "${YELLOW}[INFO] Construction de l'image Docker avec systemd...${NC}"
docker build -t openparental-systemd-test -f tests/Dockerfile.systemd .

# Nettoyage du conteneur précédent s'il existe
docker rm -f openparental-systemd 2>/dev/null || true

# Démarrage du conteneur
echo -e "${YELLOW}[INFO] Démarrage du conteneur...${NC}"
docker run -d --privileged --name openparental-systemd openparental-systemd-test

# Attente du démarrage complet
echo -e "${YELLOW}[INFO] Attente du démarrage complet de systemd...${NC}"
sleep 5

# Copie des fichiers nécessaires
echo -e "${YELLOW}[INFO] Copie des fichiers dans le conteneur...${NC}"
docker cp tests/internet-quota-test.sh openparental-systemd:/usr/local/bin/internet-quota.sh
docker exec openparental-systemd chmod +x /usr/local/bin/internet-quota.sh

# Création des services systemd
echo -e "${YELLOW}[INFO] Création des services systemd...${NC}"
docker exec openparental-systemd bash -c 'cat > /etc/systemd/system/internet-quota-track.service << EOF
[Unit]
Description=Internet Time Quota Tracking
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/internet-quota.sh track
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF'

docker exec openparental-systemd bash -c 'cat > /etc/systemd/system/internet-quota-track.timer << EOF
[Unit]
Description=Run Internet Time Quota Tracking Every Minute

[Timer]
OnBootSec=10s
OnUnitActiveSec=10s
Unit=internet-quota-track.service

[Install]
WantedBy=timers.target
EOF'

docker exec openparental-systemd bash -c 'cat > /etc/systemd/system/internet-quota-reset.service << EOF
[Unit]
Description=Reset Internet Time Quota
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/internet-quota.sh reset
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF'

docker exec openparental-systemd bash -c 'cat > /etc/systemd/system/internet-quota-reset.timer << EOF
[Unit]
Description=Reset Internet Time Quota Daily

[Timer]
OnCalendar=*-*-* 00:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF'

# Rechargement de systemd
echo -e "${YELLOW}[INFO] Rechargement de systemd...${NC}"
docker exec openparental-systemd systemctl daemon-reload

# Activation et démarrage des services
echo -e "${YELLOW}[INFO] Activation et démarrage des services...${NC}"
docker exec openparental-systemd systemctl enable internet-quota-track.timer
docker exec openparental-systemd systemctl enable internet-quota-reset.timer
docker exec openparental-systemd systemctl start internet-quota-track.timer
docker exec openparental-systemd systemctl start internet-quota-reset.timer

# Vérification des services
echo -e "${YELLOW}[INFO] Vérification des services...${NC}"
docker exec openparental-systemd systemctl status internet-quota-track.timer
docker exec openparental-systemd systemctl status internet-quota-reset.timer

# Exécution manuelle des services
echo -e "${YELLOW}[INFO] Exécution manuelle des services...${NC}"
docker exec openparental-systemd systemctl start internet-quota-reset.service
docker exec openparental-systemd systemctl start internet-quota-track.service

# Vérification des fichiers de quota
echo -e "${YELLOW}[INFO] Vérification des fichiers de quota...${NC}"
sleep 2
docker exec openparental-systemd cat /var/lib/openparental/quota/child.log || echo "Fichier non trouvé"

# Attente pour voir si le timer fonctionne
echo -e "${YELLOW}[INFO] Attente pour vérifier le fonctionnement du timer (15 secondes)...${NC}"
sleep 15

# Vérification finale
echo -e "${YELLOW}[INFO] Vérification finale des fichiers de quota...${NC}"
docker exec openparental-systemd cat /var/lib/openparental/quota/child.log || echo "Fichier non trouvé"

# Nettoyage
echo -e "${YELLOW}[INFO] Nettoyage...${NC}"
docker stop openparental-systemd
docker rm openparental-systemd

echo -e "${GREEN}=== Tests des services systemd terminés avec succès ===${NC}" 
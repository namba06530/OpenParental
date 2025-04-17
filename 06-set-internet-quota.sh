#!/bin/bash
set -euo pipefail

# Fonctions utilitaires communes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}
warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN]${NC} $1" >&2
}
error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1" >&2
    exit 1
}

# Vérification de la présence du .env
if [ ! -f ".env" ]; then
    error "Fichier .env non trouvé dans le dossier courant."
fi
source .env

# Vérification des privilèges sudo
if [ "$EUID" -ne 0 ]; then
    error "Ce script doit être exécuté avec les privilèges sudo"
fi

# Installation des dépendances nécessaires
install_dependencies() {
    log "Installation des dépendances nécessaires (iptables, sqlite3, iproute2, libnotify-bin)"
    # apt update supprimé car déjà fait au début du pipeline
    apt install -y iptables sqlite3 iproute2 libnotify-bin || error "Échec de l'installation des dépendances"
}

# Copie du script de gestion du quota et du .env
install_quota_script() {
    log "Copie du script deploy/internet-quota.sh vers /usr/local/bin/internet-quota.sh (à faire sur la machine enfant)"
    cp "$(dirname "$0")/deploy/internet-quota.sh" /usr/local/bin/internet-quota.sh
    chmod +x /usr/local/bin/internet-quota.sh
    log "Copie du fichier .env vers /usr/local/bin/.env (à faire sur la machine enfant)"
    cp .env /usr/local/bin/.env
    chmod 600 /usr/local/bin/.env
}

# Création des services systemd
create_systemd_services() {
    log "Création des services systemd pour le suivi et la réinitialisation du quota"
    # Service de suivi (track)
    cat > /etc/systemd/system/internet-quota-track.service << EOF
[Unit]
Description=Internet Time Quota Tracking
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/internet-quota.sh track
EOF
    # Timer pour le suivi (toutes les minutes)
    cat > /etc/systemd/system/internet-quota-track.timer << EOF
[Unit]
Description=Run Internet Time Quota Tracking Every Minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Unit=internet-quota-track.service

[Install]
WantedBy=timers.target
EOF
    # Service de reset
    cat > /etc/systemd/system/internet-quota-reset.service << EOF
[Unit]
Description=Reset Internet Time Quota
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/internet-quota.sh reset
EOF
    # Timer de reset (tous les jours à l'heure définie)
    cat > /etc/systemd/system/internet-quota-reset.timer << EOF
[Unit]
Description=Reset Internet Time Quota Daily

[Timer]
OnCalendar=*-*-* ${QUOTA_RESET_TIME}:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
    systemctl daemon-reload
    systemctl enable internet-quota-track.timer
    systemctl enable internet-quota-reset.timer
    systemctl start internet-quota-track.timer
    systemctl start internet-quota-reset.timer
    log "Services systemd créés et activés."
}

main() {
    log "Début de la configuration du quota Internet (mode simplifié)"
    install_dependencies
    install_quota_script
    create_systemd_services
    log "Configuration terminée."
    echo -e "\n${YELLOW}IMPORTANT :\n- Le script /usr/local/bin/internet-quota.sh doit être déployé sur chaque machine enfant.\n- Le fichier .env doit être présent dans le même dossier que le script sur la machine enfant.\n- Les services systemd sont créés pour automatiser le suivi et la réinitialisation du quota.\n- Pour toute modification, éditez le script ou le .env puis relancez ce script.\n${NC}"
}

main

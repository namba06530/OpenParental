#!/bin/bash
set -euo pipefail

# 99-final-script.sh : Sécurisation et finalisation du contrôle parental
# À exécuter en root après tous les autres scripts

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
    error "Ce script doit être exécuté avec les privilèges root (sudo)"
fi

# Chargement de la config
if [ ! -f ".env" ]; then
    error "Fichier .env non trouvé dans le dossier courant."
fi
source .env

log "Début de la phase de sécurisation finale."

# 1. Retirer l'utilisateur enfant du groupe sudo
if id -nG "$CHILD_USERNAME" | grep -qw sudo; then
    log "Retrait de $CHILD_USERNAME du groupe sudo"
    deluser "$CHILD_USERNAME" sudo
else
    log "$CHILD_USERNAME n'est pas dans le groupe sudo."
fi

# 2. Vérification des permissions sur les scripts et logs
log "Vérification des permissions sur les scripts et logs sensibles"
chmod 700 /usr/local/bin/internet-quota.sh
if [ -f /usr/local/bin/.env.quota ]; then
    chmod 600 /usr/local/bin/.env.quota
    chown root:root /usr/local/bin/.env.quota
fi
chown root:root /usr/local/bin/internet-quota.sh

# 2b. Suppression automatique des scripts d'installation et du .env
log "Suppression automatique des scripts d'installation et du .env dans $(pwd)"
rm -f 0*-*.sh 99-final-script.sh .env
log "Nettoyage terminé."

# 3. (Optionnel) Redémarrer la machine
read -p "Redémarrer la machine maintenant ? [o/N] " answer
answer=${answer:-N}
if [[ "$answer" =~ ^[oOyY]$ ]]; then
    log "Redémarrage en cours..."
    reboot
else
    log "Redémarrage annulé. Pensez à redémarrer manuellement pour appliquer toutes les restrictions."
fi

log "Sécurisation finale terminée."

#!/bin/bash
set -euo pipefail

# Fonctions utilitaires communes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Vérification des dépendances
check_dependencies() {
    log "Vérification des dépendances"
    
    # Vérifier chattr
    if ! command -v chattr >/dev/null 2>&1; then
        log "Installation de l'outil chattr (e2fsprogs)"
        apt update && apt install -y e2fsprogs || error "Impossible d'installer e2fsprogs"
    fi
    
    # Vérifier NetworkManager
    if ! command -v nmcli >/dev/null 2>&1; then
        error "NetworkManager n'est pas installé"
    fi
}

# Configuration de NetworkManager
configure_networkmanager() {
    log "Configuration de NetworkManager pour ignorer les DNS DHCP"
    
    mkdir -p "$DNS_CONF_DIR" || error "Impossible de créer le répertoire $DNS_CONF_DIR"
    
    cat > "$DNS_CONF_DIR/dns-override.conf" << EOF
[main]
dns=none
EOF
    
    if [ ! -f "$DNS_CONF_DIR/dns-override.conf" ]; then
        error "Échec de la création du fichier de configuration NetworkManager"
    fi
}

# Configuration du fichier resolv.conf
configure_resolv_conf() {
    log "Configuration du fichier resolv.conf avec les DNS Cloudflare Family"
    
    # Sauvegarde du fichier resolv.conf original
    BACKUP_DIR="/root/dns_backup"
    mkdir -p "$BACKUP_DIR"
    
    if [ -f "$RESOLV_CONF" ]; then
        if [ -L "$RESOLV_CONF" ]; then
            # Si c'est un lien symbolique, sauvegarder la cible
            cp -P "$RESOLV_CONF" "$BACKUP_DIR/resolv.conf.backup"
            cp "$(readlink -f $RESOLV_CONF)" "$BACKUP_DIR/resolv.conf.original"
        else
            cp "$RESOLV_CONF" "$BACKUP_DIR/resolv.conf.backup"
        fi
    fi
    
    # Désactivation de systemd-resolved si actif
    if systemctl is-active systemd-resolved >/dev/null 2>&1; then
        log "Arrêt de systemd-resolved"
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
    fi
    
    # Suppression du symlink si existant
    if [ -L "$RESOLV_CONF" ]; then
        log "Suppression du lien symbolique resolv.conf"
        rm -f "$RESOLV_CONF"
    fi
    
    # Création du nouveau resolv.conf
    cat > "$RESOLV_CONF" << EOF
# Configuration DNS forcée par ct_parent
# Date de modification: $(date)
nameserver $DNS_PRIMARY
nameserver $DNS_SECONDARY
EOF
    
    # Protection du fichier avec attributs immuables
    if ! chattr +i "$RESOLV_CONF" 2>/dev/null; then
        error "Impossible de protéger $RESOLV_CONF avec chattr. Vérifiez le support du système de fichiers."
    fi
}

# Vérification de la configuration
verify_dns_config() {
    log "Vérification de la configuration DNS"
    
    # Vérifier le contenu de resolv.conf
    if ! grep -q "nameserver $DNS_PRIMARY" "$RESOLV_CONF" || ! grep -q "nameserver $DNS_SECONDARY" "$RESOLV_CONF"; then
        error "La configuration DNS n'a pas été appliquée correctement"
    fi
    
    # Vérifier l'attribut immuable
    if ! lsattr "$RESOLV_CONF" | grep -q '^....i'; then
        error "L'attribut immuable n'est pas défini sur $RESOLV_CONF"
    fi
    
    # Tester la résolution DNS avec les deux serveurs
    for dns in $DNS_PRIMARY $DNS_SECONDARY; do
        if ! dig @$dns +short cloudflare.com >/dev/null; then
            warn "Le serveur DNS $dns ne répond pas"
        fi
    done
    
    log "Configuration DNS vérifiée avec succès"
}

# Redémarrage des services
restart_services() {
    log "Redémarrage des services réseau"
    
    systemctl restart NetworkManager || error "Échec du redémarrage de NetworkManager"
    
    # Attendre que le réseau soit opérationnel
    sleep 2
}

# Affichage du status final
show_status() {
    log "Configuration DNS terminée"
    log "DNS primaire   : $DNS_PRIMARY"
    log "DNS secondaire : $DNS_SECONDARY"
    log "Backup stocké dans : $BACKUP_DIR"
    
    log "Contenu actuel de $RESOLV_CONF :"
    cat "$RESOLV_CONF"
}

# Exécution principale
main() {
    log "Début de la configuration DNS"
    check_dependencies
    configure_networkmanager
    configure_resolv_conf
    restart_services
    verify_dns_config
    show_status
    log "Configuration DNS terminée avec succès"
}

# Lancement du script
main

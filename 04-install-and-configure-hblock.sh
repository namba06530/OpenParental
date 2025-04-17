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
    
    for cmd in curl shasum systemctl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "Commande requise non trouvée: $cmd"
        fi
    done
}

# Installation de hBlock
install_hblock() {
    log "Installation de hBlock ${HBLOCK_VERSION}"
    
    # Téléchargement et vérification de hBlock
    curl -o /tmp/hblock "https://raw.githubusercontent.com/hectorm/hblock/${HBLOCK_VERSION}/hblock" || \
        error "Échec du téléchargement de hBlock"
    
    echo "${HBLOCK_BINARY_SHA}  /tmp/hblock" | shasum -c || error "Vérification SHA256 échouée"
    
    # Installation de hBlock
    mv /tmp/hblock /usr/local/bin/hblock || error "Impossible de déplacer hBlock"
    chown 0:0 /usr/local/bin/hblock
    chmod 755 /usr/local/bin/hblock
    
    log "hBlock installé avec succès"
}

# Installation des services systemd
install_systemd_services() {
    log "Installation des services systemd"
    
    # Téléchargement des fichiers service et timer
    curl -o '/tmp/hblock.service' "https://raw.githubusercontent.com/hectorm/hblock/${HBLOCK_VERSION}/resources/systemd/hblock.service"
    curl -o '/tmp/hblock.timer' "https://raw.githubusercontent.com/hectorm/hblock/${HBLOCK_VERSION}/resources/systemd/hblock.timer"
    
    # Vérification des checksums
    echo "${HBLOCK_SERVICE_SHA}  /tmp/hblock.service" | shasum -c || error "Vérification SHA256 du service échouée"
    echo "${HBLOCK_TIMER_SHA}  /tmp/hblock.timer" | shasum -c || error "Vérification SHA256 du timer échouée"
    
    # Installation des unités systemd
    mv /tmp/hblock.{service,timer} /etc/systemd/system/ || error "Impossible de déplacer les fichiers systemd"
    chown 0:0 /etc/systemd/system/hblock.{service,timer}
    chmod 644 /etc/systemd/system/hblock.{service,timer}
    
    # Rechargement et activation
    systemctl daemon-reload
    systemctl enable hblock.timer
    systemctl start hblock.timer
    
    log "Services systemd installés et activés"
}

# Configuration de hBlock
configure_hblock() {
    log "Configuration de hBlock"
    
    # Création du fichier de configuration
    mkdir -p /etc/hblock
    
    # Configuration des sources de blocage
    local sources=""
    for list in "${HBLOCK_LISTS[@]}"; do
        sources+="$list\n"
    done
    
    echo -e "$sources" > /etc/hblock/sources.list
    
    # Configuration des options hBlock
    cat > /etc/hblock/config << EOF
# Configuration hBlock
ALLOW_REDIRECTIONS=true
BLOCK_MINING=true
VERIFY_SOURCES=true
EOF
    
    log "Configuration de hBlock terminée"
}

# Première exécution et vérification
verify_hblock() {
    log "Première exécution de hBlock"
    
    # Vérifier et sauvegarder le fichier hosts original
    if [ -f "/etc/hosts" ]; then
        log "Sauvegarde du fichier hosts original"
        cp /etc/hosts /etc/hosts.backup
    fi
    
    # Vérifier si le fichier hosts a des attributs immuables
    if lsattr /etc/hosts 2>/dev/null | grep -q '^....i'; then
        log "Suppression de l'attribut immuable sur /etc/hosts"
        chattr -i /etc/hosts
    fi
    
    # S'assurer que le fichier est modifiable
    chmod 644 /etc/hosts
    
    # Exécuter hBlock
    log "Exécution de hBlock..."
    if ! hblock; then
        error "Échec de l'exécution de hBlock"
    fi
    
    # Vérification plus robuste
    if ! grep -q "^0\.0\.0\.0" /etc/hosts; then
        # Afficher le contenu pour le diagnostic
        log "Contenu actuel de /etc/hosts:"
        cat /etc/hosts
        error "Le fichier hosts n'a pas été mis à jour correctement"
    fi
    
    log "hBlock fonctionne correctement"
    log "Nombre de domaines bloqués: $(grep -c "^0\.0\.0\.0" /etc/hosts)"
}

# Affichage du statut
show_status() {
    log "Installation de hBlock terminée"
    log "Version installée : ${HBLOCK_VERSION}"
    log "Mise à jour automatique : ${HBLOCK_UPDATE_FREQUENCY}"
    log "Nombre de listes de blocage : ${#HBLOCK_LISTS[@]}"
    
    # Afficher le prochain horaire de mise à jour
    NEXT_UPDATE=$(systemctl show hblock.timer --property=NextElapseUSecRealtime | cut -d= -f2)
    if [ -n "$NEXT_UPDATE" ]; then
        log "Prochaine mise à jour : $NEXT_UPDATE"
    fi
}

# Exécution principale
main() {
    log "Début de l'installation de hBlock"
    check_dependencies
    install_hblock
    install_systemd_services
    configure_hblock
    verify_hblock
    show_status
    log "Installation de hBlock terminée avec succès"
}

# Lancement du script
main
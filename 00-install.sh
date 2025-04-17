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

section() {
    echo -e "${BLUE}========== $1 ==========${NC}"
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

# Vérification du répertoire de travail
if [ ! -f "00-install.sh" ]; then
    error "Ce script doit être exécuté depuis le répertoire ct_parent"
fi

# Vérification des prérequis système
check_prerequisites() {
    section "Vérification des prérequis"
    
    # Vérification de la distribution
    if ! grep -q "Ubuntu" /etc/os-release; then
        error "Ce script nécessite Ubuntu"
    fi
    
    # Vérification des paquets requis
    local required_packages=(
        "iptables"
        "sqlite3"
        "curl"
    )
    
    local missing_packages=()
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -ne 0 ]; then
        log "Installation des paquets manquants : ${missing_packages[*]}"
        apt update
        apt install -y "${missing_packages[@]}" || error "Impossible d'installer les paquets requis"
    fi
    
    log "Tous les prérequis sont satisfaits"
}

# Exécution d'un script
run_script() {
    local script=$1
    local name=$2
    
    section "Exécution de $name"
    
    if [ ! -f "$script" ]; then
        error "Script non trouvé : $script"
    fi
    
    chmod +x "$script"
    bash "$script"
    # if ! bash "$script"; then
        # error "Échec de l'exécution de $script"
    # fi
    
    log "$name terminé avec succès"
}

# Exécution principale
main() {
    clear
    section "Installation du contrôle parental"

    # 1. Régler le fuseau horaire (interactif)
    section "Configuration du fuseau horaire (tzdata)"
    sleep 3
    dpkg-reconfigure tzdata

    # 2. Mettre à jour le système
    section "Mise à jour du système (apt update & upgrade)"
    apt update
    # apt upgrade -y

    # 3. Installer un antivirus (ClamAV)
    section "Installation de l'antivirus ClamAV (optionnel)"
    apt install -y clamav clamav-daemon
    systemctl enable clamav-freshclam && systemctl start clamav-freshclam

    # Source du fichier .env
    source .env
    
    # Vérification des prérequis
    check_prerequisites
    
    # Exécution des scripts dans l'ordre
    scripts=(
        "01-create-hidden-admin-user.sh:Création du compte administrateur..."
        "02-install-and-configure-ssh.sh:Configuration SSH..."
        "03-force-custom-dns.sh:Configuration DNS..."
        "04-install-and-configure-hblock.sh:Installation hBlock..."
        "05-install-and-configure-Timekpr.sh:Installation Timekpr..."
        "06-set-internet-quota.sh:Configuration des quotas Internet..."
        "99-final-script.sh:Phase de sécurisation finale..."
    )

    for entry in "${scripts[@]}"; do
        script="${entry%%:*}"
        name="${entry#*:}"
        run_script "$script" "$name"
    done
    
    section "Installation terminée"
    log "L'installation du contrôle parental est terminée avec succès"
    log "Utilisateur admin : $ADMIN_USERNAME"
    log "Utilisateur enfant : $CHILD_USERNAME"
    log "Quota Internet : $QUOTA_DAILY_MINUTES minutes par jour"
    log "Temps d'écran : $TIMEKPR_DAILY_LIMIT_SECONDS secondes par jour"
}

# Gestion des erreurs
set -e
trap 'error "Une erreur est survenue lors de l installation"' ERR

# Lancement du script
main
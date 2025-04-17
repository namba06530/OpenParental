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

# Installation de Timekpr-nExT
install_timekpr() {
    log "Installation de Timekpr-nExT"
    
    # Ajout du PPA
    if ! add-apt-repository -y ppa:mjasnik/ppa; then
        error "Impossible d'ajouter le PPA Timekpr"
    fi
    
    # Mise à jour des paquets (inutile, déjà fait au début du pipeline)
    # apt update || error "Échec de la mise à jour des paquets"
    
    # Installation de Timekpr
    apt install -y timekpr-next || error "Échec de l'installation de Timekpr"
    
    log "Timekpr-nExT installé avec succès"
}

# Configuration de base de Timekpr
configure_timekpr() {
    log "Configuration de Timekpr pour l'utilisateur $CHILD_USERNAME"
    
    # Vérifier que l'utilisateur existe
    if ! id "$CHILD_USERNAME" >/dev/null 2>&1; then
        error "L'utilisateur $CHILD_USERNAME n'existe pas"
    fi
    
    # Attendre que le service soit prêt
    echo "Attente de 5 secondes pour que le service Timekpr soit prêt..."
    sleep 5
    
    
    # Configuration des jours autorisés
    if ! timekpra --setalloweddays "$CHILD_USERNAME" "$TIMEKPR_WORK_DAYS"; then
        error "Impossible de configurer les jours autorisés"
    fi
    
    # Configuration des heures autorisées
    if ! timekpra --setallowedhours "$CHILD_USERNAME" "ALL" "$TIMEKPR_ALLOWED_HOURS"; then
        error "Impossible de configurer les heures autorisées"
    fi
    
    # Configuration des limites quotidiennes
    # Construire la chaîne des limites pour chaque jour
    # IFS=',' read -ra DAYS <<< "$TIMEKPR_WORK_DAYS"
    # LIMITS=""
    # for day in "${DAYS[@]}"; do
    #    [ -n "$LIMITS" ] && LIMITS+=";$TIMEKPR_DAILY_LIMIT_SECONDS" || LIMITS="$TIMEKPR_DAILY_LIMIT_SECONDS"
    # done
    
    if ! timekpra --settimelimits "$CHILD_USERNAME" "$TIMEKPR_DAILY_LIMIT_SECONDS"; then
        error "Impossible de configurer les limites quotidiennes"
    fi
    
    # Configuration de la limite hebdomadaire
    if ! timekpra --settimelimitweek "$CHILD_USERNAME" "$TIMEKPR_WEEKLY_LIMIT_SECONDS"; then
        error "Impossible de configurer la limite hebdomadaire"
    fi

    # Configuration de la limite mensuelle
    if ! timekpra --settimelimitmonth "$CHILD_USERNAME" "$TIMEKPR_MONTHLY_LIMIT_SECONDS"; then
        error "Impossible de configurer la limite mensuelle"
    fi
    
    log "Configuration de base terminée"
}

# Configuration avancée
configure_advanced_settings() {
    log "Configuration des paramètres avancés"
    
    # Configuration du type de déconnexion
    if ! timekpra --setlockouttype "$CHILD_USERNAME" "$TIMEKPR_AUTO_LOGOUT"; then
        error "Impossible de configurer le type de déconnexion"
    fi
    
    # Configuration du suivi d'inactivité
    if ! timekpra --settrackinactive "$CHILD_USERNAME" "$TIMEKPR_TRACK_INACTIVITY"; then
        error "Impossible de configurer le suivi d'inactivité"
    fi
    
    # Configuration de l'icône de la barre des tâches
    if ! timekpra --sethidetrayicon "$CHILD_USERNAME" "$TIMEKPR_HIDE_TRAY"; then
        error "Impossible de configurer l'icône"
    fi
    
    log "Configuration avancée terminée"
}

# Vérification de la configuration
verify_configuration() {
    log "Vérification de la configuration"
    
    # Vérifier que le service est actif
    if ! systemctl is-active --quiet timekpr.service; then
        error "Le service Timekpr n'est pas actif"
    fi
    
    # Récupérer et vérifier les informations de l'utilisateur
    if ! timekpra --userinfo "$CHILD_USERNAME" | grep -q "LIMITS_PER_WEEKDAYS: $TIMEKPR_DAILY_LIMIT_SECONDS"; then
        warn "La limite quotidienne pourrait ne pas être correctement configurée"
    fi
    
    log "Configuration vérifiée avec succès"
}

# Affichage du statut
show_status() {
    log "Configuration de Timekpr terminée"
    log "Utilisateur configuré : $CHILD_USERNAME"
    log "Limite quotidienne : $TIMEKPR_DAILY_LIMIT_SECONDS secondes"
    log "Heures d'accès : $TIMEKPR_START_TIME - $TIMEKPR_END_TIME"
    
    # Afficher la configuration complète
    timekpra --userinfo "$CHILD_USERNAME"
}

# Exécution principale
main() {
    log "Début de l'installation et configuration de Timekpr"
    install_timekpr
    configure_timekpr
    configure_advanced_settings
    verify_configuration
    show_status
    log "Installation et configuration de Timekpr terminées avec succès"
}

# Lancement du script
main
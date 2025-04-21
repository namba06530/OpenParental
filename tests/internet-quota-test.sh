#!/bin/bash
set -euo pipefail

# Journalisation simple
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /tmp/quota-debug.log
}

# Configuration
QUOTA_SESSION_DIR="/var/lib/openparental/quota"
CHILD_USERNAME="child"  # L'utilisateur dans le conteneur de test

log "Script started with arguments: $@"

# Vérification des arguments
if [ "$#" -lt 1 ]; then
    log "Usage: $0 {track|reset}"
    exit 1
fi

# Fonctions de base
reset_quota() {
    log "Resetting quota for $CHILD_USERNAME"
    
    # Vérifier le répertoire
    if [ ! -d "$QUOTA_SESSION_DIR" ]; then
        mkdir -p "$QUOTA_SESSION_DIR"
        chmod 700 "$QUOTA_SESSION_DIR"
    fi
    
    # Réinitialiser le quota
    echo "0" > "$QUOTA_SESSION_DIR/${CHILD_USERNAME}.log"
    chmod 600 "$QUOTA_SESSION_DIR/${CHILD_USERNAME}.log"
    chown "$CHILD_USERNAME:$CHILD_USERNAME" "$QUOTA_SESSION_DIR/${CHILD_USERNAME}.log"
    
    log "Quota reset successful"
    return 0
}

track_quota() {
    log "Tracking quota for $CHILD_USERNAME"
    
    # Lire le quota actuel
    if [ ! -f "$QUOTA_SESSION_DIR/${CHILD_USERNAME}.log" ]; then
        echo "0" > "$QUOTA_SESSION_DIR/${CHILD_USERNAME}.log"
        chmod 600 "$QUOTA_SESSION_DIR/${CHILD_USERNAME}.log"
        chown "$CHILD_USERNAME:$CHILD_USERNAME" "$QUOTA_SESSION_DIR/${CHILD_USERNAME}.log"
    fi
    
    CURRENT_MINUTES=$(cat "$QUOTA_SESSION_DIR/${CHILD_USERNAME}.log")
    NEW_MINUTES=$((CURRENT_MINUTES + 1))
    
    # Mettre à jour le quota
    echo "$NEW_MINUTES" > "$QUOTA_SESSION_DIR/${CHILD_USERNAME}.log"
    chmod 600 "$QUOTA_SESSION_DIR/${CHILD_USERNAME}.log"
    chown "$CHILD_USERNAME:$CHILD_USERNAME" "$QUOTA_SESSION_DIR/${CHILD_USERNAME}.log"
    
    log "Quota updated to $NEW_MINUTES minutes"
    return 0
}

# Exécution principale
case "$1" in
    "track")
        log "Executing track_quota"
        track_quota
        ;;
    "reset")
        log "Executing reset_quota"
        reset_quota
        ;;
    *)
        log "Invalid argument: $1"
        log "Usage: $0 {track|reset}"
        exit 1
        ;;
esac

log "Script completed successfully"
exit 0 
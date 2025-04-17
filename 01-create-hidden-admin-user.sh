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

# Vérification de l'existence du compte enfant
check_child_account() {
    log "Vérification du compte enfant"
    if ! id "$CHILD_USERNAME" >/dev/null 2>&1; then
        log "Le compte enfant $CHILD_USERNAME n'existe pas, création..."
        useradd -m -s /bin/bash "$CHILD_USERNAME"
        # Demander un mot de passe pour le compte enfant
        passwd "$CHILD_USERNAME"
    else
        log "Le compte enfant $CHILD_USERNAME existe déjà"
    fi
}

# Sauvegarde du mot de passe admin dans .env de manière sécurisée
save_admin_password() {
    local password=$1
    local env_file=".env"
    local temp_file=$(mktemp)
    
    # Créer une copie temporaire du fichier .env sans la ligne ADMIN_PASSWORD
    grep -v "^ADMIN_PASSWORD=" "$env_file" > "$temp_file"
    # Ajouter le nouveau mot de passe
    echo "ADMIN_PASSWORD='$password'" >> "$temp_file"
    # Remplacer l'ancien fichier
    mv "$temp_file" "$env_file"
    chmod 600 "$env_file"
}

# Vérification et création de l'utilisateur admin
create_admin_user() {
    if id "$ADMIN_USERNAME" &>/dev/null; then
        log "L'utilisateur $ADMIN_USERNAME existe déjà"
    else
        log "Création de l'utilisateur $ADMIN_USERNAME"
        
        # Si le mot de passe n'est pas défini dans .env, le demander
        if [ -z "$ADMIN_PASSWORD" ]; then
            read -s -p "Entrez le mot de passe pour $ADMIN_USERNAME: " ADMIN_PASSWORD
            echo
            read -s -p "Confirmez le mot de passe: " ADMIN_PASSWORD_CONFIRM
            echo
            
            if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
                error "Les mots de passe ne correspondent pas"
            fi
            
            # Sauvegarder le mot de passe dans .env
            # save_admin_password "$ADMIN_PASSWORD"
        fi
        
        # Création de l'utilisateur avec mot de passe
        useradd -m -s /bin/bash "$ADMIN_USERNAME"
        echo "$ADMIN_USERNAME:$ADMIN_PASSWORD" | chpasswd
    fi
    # Ajout aux groupes spécifiés (toujours exécuté)
    usermod -aG "$ADMIN_GROUPS" "$ADMIN_USERNAME"
}

# Configuration pour masquer l'utilisateur admin
configure_user_visibility() {
    if [ "$HIDE_ADMIN_USER" = true ]; then
        log "Configuration pour masquer l'utilisateur $ADMIN_USERNAME"
        
        mkdir -p "$ACCOUNTS_SERVICE_DIR"
        cat > "$ACCOUNTS_SERVICE_DIR/$ADMIN_USERNAME" << EOF
[User]
SystemAccount=true
EOF
        chmod 644 "$ACCOUNTS_SERVICE_DIR/$ADMIN_USERNAME"
        
        # Redémarrage du service d'affichage si nécessaire
        if systemctl is-active "$DISPLAY_MANAGER" >/dev/null 2>&1; then
            log "Redémarrage de $DISPLAY_MANAGER"
            systemctl restart "$DISPLAY_MANAGER"
        fi
    fi
}

# Exécution principale
main() {
    log "Début de la configuration des utilisateurs"
    check_child_account
    create_admin_user
    configure_user_visibility
    log "Configuration terminée avec succès"
}

# Lancement du script
main


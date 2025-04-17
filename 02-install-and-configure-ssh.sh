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

# Sauvegarde de la clé SSH dans .env
save_ssh_key() {
    local key=$1
    local env_file=".env"
    local temp_file=$(mktemp)
    
    grep -v "^SSH_PUBLIC_KEY=" "$env_file" > "$temp_file"
    echo "SSH_PUBLIC_KEY='$key'" >> "$temp_file"
    mv "$temp_file" "$env_file"
    chmod 600 "$env_file"
}

# Installation du serveur SSH
install_ssh_server() {
    log "Installation du serveur SSH"
    apt install -y openssh-server || error "Impossible d'installer openssh-server"
    systemctl enable ssh
    systemctl start ssh
}

# Configuration du répertoire .ssh
setup_ssh_directory() {
    log "Configuration du répertoire SSH pour $ADMIN_USERNAME"
    
    # Création du répertoire .ssh et backup
    SSH_DIR="/home/$ADMIN_USERNAME/.ssh"
    SSH_BACKUP_DIR="/root/.ssh/backup"
    
    mkdir -p "$SSH_DIR" "$SSH_BACKUP_DIR"
    
    # Si la clé publique n'est pas dans .env, la demander
    if [ -z "$SSH_PUBLIC_KEY" ]; then
        read -p "Entrez la clé publique SSH pour $ADMIN_USERNAME: " SSH_PUBLIC_KEY
        if [ -z "$SSH_PUBLIC_KEY" ]; then
            error "La clé publique SSH est requise"
        fi
        # Sauvegarder la clé dans .env
        save_ssh_key "$SSH_PUBLIC_KEY"
    fi
    
    # Création du fichier authorized_keys et backup
    echo "$SSH_PUBLIC_KEY" > "$SSH_DIR/authorized_keys"
    cp "$SSH_DIR/authorized_keys" "$SSH_BACKUP_DIR/authorized_keys_$ADMIN_USERNAME"
    
    # Configuration des permissions
    chown -R "$ADMIN_USERNAME:$ADMIN_USERNAME" "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    chmod 600 "$SSH_DIR/authorized_keys"
    chmod 700 "$SSH_BACKUP_DIR"
    chmod 600 "$SSH_BACKUP_DIR/authorized_keys_$ADMIN_USERNAME"
}

# Configuration sécurisée de SSH
configure_ssh() {
    log "Configuration sécurisée de SSH"
    
    SSHD_CONFIG="/etc/ssh/sshd_config"
    
    # Sauvegarde du fichier de configuration original
    cp "$SSHD_CONFIG" "${SSHD_CONFIG}.backup"
    
    # Expansion de la variable ADMIN_USERNAME dans AllowUsers
    local allowed_users="${ADMIN_USERNAME}"
    
    # Configuration SSH sécurisée
    cat > "$SSHD_CONFIG" << EOF
# Configuration SSH sécurisée
Port ${SSH_PORT}
PermitRootLogin ${SSH_PERMIT_ROOT_LOGIN}
PasswordAuthentication ${SSH_PASSWORD_AUTHENTICATION}
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
AllowUsers ${allowed_users}
Protocol 2
X11Forwarding no
UsePAM yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 0
EOF
    
    # Test de la configuration
    sshd -t || error "Configuration SSH invalide"
    
    # Redémarrage du service SSH
    systemctl restart ssh
}

# Vérification finale
verify_ssh() {
    log "Vérification de la configuration SSH"
    
    # Vérifier le service
    if ! systemctl is-active --quiet ssh; then
        error "Le service SSH n'est pas actif"
    fi
    
    # Vérifier la configuration
    if ! grep -q "^Port ${SSH_PORT}" "$SSHD_CONFIG"; then
        error "La configuration du port SSH n'a pas été appliquée"
    fi
    
    # Vérifier les backups
    if [ ! -f "/root/.ssh/backup/authorized_keys_$ADMIN_USERNAME" ]; then
        error "La sauvegarde de la clé SSH n'existe pas"
    fi
    
    log "Configuration SSH vérifiée avec succès"
}

# Exécution principale
main() {
    log "Début de la configuration SSH"
    install_ssh_server
    setup_ssh_directory
    configure_ssh
    verify_ssh
    log "Configuration SSH terminée avec succès"
}

# Lancement du script
main


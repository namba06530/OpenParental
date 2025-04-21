#!/bin/bash
# install.sh - Installation script for Internet Quota System
# This script installs the internet quota system on the target machine

# Set error handling
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner function
print_banner() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}      Installation du Quota Internet       ${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    log_error "Ce script doit être exécuté en tant que root ou avec sudo"
    exit 1
fi

# Print banner
print_banner

# Check dependencies
log_info "Vérification des dépendances..."
DEPS=("bash" "mkdir" "chmod" "systemctl")
MISSING_DEPS=()

for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    log_error "Dépendances manquantes: ${MISSING_DEPS[*]}"
    exit 1
fi

log_info "Toutes les dépendances sont satisfaites."

# Create directories
log_info "Création des répertoires..."
mkdir -p /usr/local/lib/internet-quota/modules
mkdir -p /var/lib/internet-quota
mkdir -p /etc/internet-quota
mkdir -p /var/log/internet-quota

# Install scripts
log_info "Installation des scripts..."
cp -f src/internet-quota.sh /usr/local/bin/internet-quota
chmod 755 /usr/local/bin/internet-quota

cp -f src/modules/*.sh /usr/local/lib/internet-quota/modules/
chmod 644 /usr/local/lib/internet-quota/modules/*.sh

# Set permissions on directories
log_info "Configuration des permissions..."
chmod 750 /var/lib/internet-quota
chmod 750 /etc/internet-quota
chmod 750 /var/log/internet-quota

# Install systemd services
log_info "Installation des services systemd..."
cp -f src/systemd/*.service /etc/systemd/system/
cp -f src/systemd/*.timer /etc/systemd/system/

chmod 644 /etc/systemd/system/internet-quota-*.service
chmod 644 /etc/systemd/system/internet-quota-*.timer

# Reload systemd
log_info "Rechargement de systemd..."
systemctl daemon-reload

# Initialize quota system
log_info "Initialisation du système de quota internet..."
/usr/local/bin/internet-quota init

# Prompt for user configuration
echo ""
log_info "Configuration de l'utilisateur à surveiller..."
read -p "Nom d'utilisateur à surveiller: " username

if [ -n "$username" ]; then
    if id "$username" &>/dev/null; then
        /usr/local/bin/internet-quota config USER="$username"
        log_info "Utilisateur configuré: $username"
    else
        log_warning "L'utilisateur '$username' n'existe pas. Configuration ignorée."
    fi
fi

# Prompt for quota configuration
echo ""
log_info "Configuration du quota journalier..."
read -p "Quota journalier en minutes [60]: " quota

if [ -n "$quota" ]; then
    /usr/local/bin/internet-quota config QUOTA="$quota"
    log_info "Quota configuré: $quota minutes"
else
    log_info "Utilisation du quota par défaut: 60 minutes"
fi

# Ask if services should be enabled and started
echo ""
log_info "Activation des services..."
read -p "Activer et démarrer les services? [O/n]: " enable_services

if [ -z "$enable_services" ] || [[ "$enable_services" =~ ^[OoYy]$ ]]; then
    # Enable and start services
    systemctl enable internet-quota-reset.timer
    systemctl enable internet-quota-track.timer
    systemctl start internet-quota-reset.timer
    systemctl start internet-quota-track.timer
    log_info "Services activés et démarrés."
else
    log_info "Les services n'ont pas été activés. Vous pouvez les activer manuellement plus tard."
fi

# Show status
echo ""
log_info "Installation terminée avec succès!"
echo ""
log_info "Statut actuel du quota:"
/usr/local/bin/internet-quota status

echo ""
log_info "Pour afficher l'aide, exécutez: internet-quota help"
echo ""
echo -e "${BLUE}============================================${NC}" 
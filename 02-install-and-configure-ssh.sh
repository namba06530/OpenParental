#!/bin/bash
set -euo pipefail

# Common utility functions
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

# Check for .env file presence
if [ ! -f ".env" ]; then
    error ".env file not found in the current directory."
fi
source .env

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
    error "This script must be run with sudo privileges."
fi

# Save SSH key in .env
save_ssh_key() {
    local key=$1
    local env_file=".env"
    local temp_file=$(mktemp)
    grep -v "^SSH_PUBLIC_KEY=" "$env_file" > "$temp_file"
    echo "SSH_PUBLIC_KEY='$key'" >> "$temp_file"
    mv "$temp_file" "$env_file"
    chmod 600 "$env_file"
}

# Install SSH server
install_ssh_server() {
    log "Installing SSH server"
    apt install -qq -y openssh-server || error "Unable to install openssh-server"
    systemctl enable ssh
    systemctl start ssh
}

# Setup .ssh directory
setup_ssh_directory() {
    log "Setting up SSH directory for $ADMIN_USERNAME"
    SSH_DIR="/home/$ADMIN_USERNAME/.ssh"
    SSH_BACKUP_DIR="/root/.ssh/backup"
    mkdir -p "$SSH_DIR" "$SSH_BACKUP_DIR"
    # If public key is not in .env, prompt for it
    if [ -z "$SSH_PUBLIC_KEY" ]; then
        read -p "Enter SSH public key for $ADMIN_USERNAME: " SSH_PUBLIC_KEY
        if [ -z "$SSH_PUBLIC_KEY" ]; then
            error "SSH public key is required"
        fi
        # Save key in .env
        save_ssh_key "$SSH_PUBLIC_KEY"
    fi
    # Create authorized_keys and backup
    echo "$SSH_PUBLIC_KEY" > "$SSH_DIR/authorized_keys"
    cp "$SSH_DIR/authorized_keys" "$SSH_BACKUP_DIR/authorized_keys_$ADMIN_USERNAME"
    # Set permissions
    chown -R "$ADMIN_USERNAME:$ADMIN_USERNAME" "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    chmod 600 "$SSH_DIR/authorized_keys"
    chmod 700 "$SSH_BACKUP_DIR"
    chmod 600 "$SSH_BACKUP_DIR/authorized_keys_$ADMIN_USERNAME"
}

# Secure SSH configuration
configure_ssh() {
    log "Securing SSH configuration"
    SSHD_CONFIG="/etc/ssh/sshd_config"
    # Backup original config
    cp "$SSHD_CONFIG" "${SSHD_CONFIG}.backup"
    # Expand ADMIN_USERNAME in AllowUsers
    local allowed_users="${ADMIN_USERNAME}"
    # Secure SSH config
    cat > "$SSHD_CONFIG" << EOF
# Secure SSH configuration
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
    # Test configuration
    sshd -t || error "Invalid SSH configuration"
    # Restart SSH service
    systemctl restart ssh
}

# Final verification
verify_ssh() {
    log "Verifying SSH configuration"
    # Check service
    if (! systemctl is-active --quiet ssh); then
        error "SSH service is not active"
    fi
    # Check config
    if (! grep -q "^Port ${SSH_PORT}" "$SSHD_CONFIG"); then
        error "SSH port configuration was not applied"
    fi
    # Check backups
    if [ ! -f "/root/.ssh/backup/authorized_keys_$ADMIN_USERNAME" ]; then
        error "SSH key backup does not exist"
    fi
    log "SSH configuration successfully verified"
}

# Main execution
main() {
    log "Starting SSH configuration"
    install_ssh_server
    setup_ssh_directory
    configure_ssh
    verify_ssh
    log "SSH configuration completed successfully"
}

# Script entry point
main


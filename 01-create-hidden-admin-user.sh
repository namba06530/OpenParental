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

# Check if child account exists
check_child_account() {
    log "Checking child account"
    if ! id "$CHILD_USERNAME" >/dev/null 2>&1; then
        log "Child account $CHILD_USERNAME does not exist, creating..."
        useradd -m -s /bin/bash "$CHILD_USERNAME"
        # Prompt for child account password
        passwd "$CHILD_USERNAME"
    else
        log "Child account $CHILD_USERNAME already exists"
    fi
}

# Securely save admin password in .env
save_admin_password() {
    local password=$1
    local env_file=".env"
    local temp_file=$(mktemp)
    # Create a temporary copy of .env without ADMIN_PASSWORD line
    grep -v "^ADMIN_PASSWORD=" "$env_file" > "$temp_file"
    # Add the new password
    echo "ADMIN_PASSWORD='$password'" >> "$temp_file"
    # Replace the old file
    mv "$temp_file" "$env_file"
    chmod 600 "$env_file"
}

# Check and create admin user
create_admin_user() {
    if id "$ADMIN_USERNAME" &>/dev/null; then
        log "User $ADMIN_USERNAME already exists"
    else
        log "Creating user $ADMIN_USERNAME"
        # If password is not set in .env, prompt for it
        if [ -z "$ADMIN_PASSWORD" ]; then
            read -s -p "Enter password for $ADMIN_USERNAME: " ADMIN_PASSWORD
            echo
            read -s -p "Confirm password: " ADMIN_PASSWORD_CONFIRM
            echo
            if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
                error "Passwords do not match"
            fi
        fi
        # Create user with password
        useradd -m -s /bin/bash "$ADMIN_USERNAME"
        echo "$ADMIN_USERNAME:$ADMIN_PASSWORD" | chpasswd
    fi
    # Always add to specified groups
    usermod -aG "$ADMIN_GROUPS" "$ADMIN_USERNAME"
}

# Configure admin user visibility
configure_user_visibility() {
    if [ "$HIDE_ADMIN_USER" = true ]; then
        log "Configuring to hide user $ADMIN_USERNAME from login screen"
        mkdir -p "$ACCOUNTS_SERVICE_DIR"
        cat > "$ACCOUNTS_SERVICE_DIR/$ADMIN_USERNAME" << EOF
[User]
SystemAccount=true
EOF
        chmod 644 "$ACCOUNTS_SERVICE_DIR/$ADMIN_USERNAME"
        # Optionally restart display manager if needed
        # if systemctl is-active "$DISPLAY_MANAGER" >/dev/null 2>&1; then
            # log "Restarting $DISPLAY_MANAGER"
            # systemctl restart "$DISPLAY_MANAGER"
        # fi
    fi
}

# Main execution
main() {
    log "Starting user configuration"
    check_child_account
    create_admin_user
    configure_user_visibility
    log "User configuration completed successfully"
}

# Script entry point
main


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

# Check dependencies
check_dependencies() {
    log "Checking dependencies"
    # Check chattr
    if ! command -v chattr >/dev/null 2>&1; then
        log "Installing chattr tool (e2fsprogs)"
        apt install -qq -y e2fsprogs || error "Unable to install e2fsprogs"
    fi
    # Check NetworkManager
    if ! command -v nmcli >/dev/null 2>&1; then
        error "NetworkManager is not installed"
    fi
}

# Configure NetworkManager
configure_networkmanager() {
    log "Configuring NetworkManager to ignore DHCP DNS"
    mkdir -p "$DNS_CONF_DIR" || error "Unable to create directory $DNS_CONF_DIR"
    cat > "$DNS_CONF_DIR/dns-override.conf" << EOF
[main]
dns=none
EOF
    if [ ! -f "$DNS_CONF_DIR/dns-override.conf" ]; then
        error "Failed to create NetworkManager configuration file"
    fi
}

# Configure resolv.conf
configure_resolv_conf() {
    log "Configuring resolv.conf with Cloudflare Family DNS"
    BACKUP_DIR="/root/dns_backup"
    mkdir -p "$BACKUP_DIR"
    if [ -f "$RESOLV_CONF" ]; then
        if [ -L "$RESOLV_CONF" ]; then
            cp --remove-destination "$RESOLV_CONF" "$BACKUP_DIR/resolv.conf.symlink"
            cp --remove-destination "$(readlink -f "$RESOLV_CONF")" "$BACKUP_DIR/resolv.conf.original"
        else
            cp --remove-destination "$RESOLV_CONF" "$BACKUP_DIR/resolv.conf.backup"
        fi
    fi
    # Disable systemd-resolved if active
    if systemctl is-active systemd-resolved >/dev/null 2>&1; then
        log "Stopping systemd-resolved"
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
    fi
    # Remove symlink if exists
    if [ -L "$RESOLV_CONF" ]; then
        log "Removing resolv.conf symlink"
        rm -f "$RESOLV_CONF"
    fi
    # Create new resolv.conf
    cat > "$RESOLV_CONF" << EOF
# DNS configuration forced by OpenParental
# Last modified: $(date)
nameserver $DNS_PRIMARY
nameserver $DNS_SECONDARY
EOF
    # Protect file with immutable attribute
    if ! chattr +i "$RESOLV_CONF" 2>/dev/null; then
        error "Unable to protect $RESOLV_CONF with chattr. Check filesystem support."
    fi
}

# Verify DNS configuration
verify_dns_config() {
    log "Verifying DNS configuration"
    # Check resolv.conf content
    if ! grep -q "nameserver $DNS_PRIMARY" "$RESOLV_CONF" || ! grep -q "nameserver $DNS_SECONDARY" "$RESOLV_CONF"; then
        error "DNS configuration was not applied correctly"
    fi
    # Check immutable attribute
    if ! lsattr "$RESOLV_CONF" | grep -q '^....i'; then
        error "Immutable attribute is not set on $RESOLV_CONF"
    fi
    # Test DNS resolution with both servers
    for dns in $DNS_PRIMARY $DNS_SECONDARY; do
        if ! dig @$dns +short cloudflare.com >/dev/null; then
            warn "DNS server $dns is not responding"
        fi
    done
    log "DNS configuration successfully verified"
}

# Restart services
restart_services() {
    log "Restarting network services"
    systemctl restart NetworkManager || error "Failed to restart NetworkManager"
    # Wait for network to be up
    sleep 2
}

# Show final status
show_status() {
    log "DNS configuration completed"
    log "Primary DNS   : $DNS_PRIMARY"
    log "Secondary DNS : $DNS_SECONDARY"
    log "Backup stored in : $BACKUP_DIR"
    log "Current content summary of $RESOLV_CONF :"
    echo -e "${BLUE}----------------------${NC}"
    grep '^nameserver' "$RESOLV_CONF" | while read -r line; do
        echo -e "${BLUE}$line${NC}"
    done
    echo -e "${BLUE}----------------------${NC}"
}

# Main execution
main() {
    log "Starting DNS configuration"
    check_dependencies
    configure_networkmanager
    configure_resolv_conf
    restart_services
    verify_dns_config
    show_status
    log "DNS configuration completed successfully"
}

# Script entry point
main

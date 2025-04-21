#!/bin/bash
set -euo pipefail

# Get the project root directory (where .env should be)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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

section() {
    echo -e "\n${BLUE}========== $1 ==========${NC}\n"
}

# Check for .env file presence
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo "Error: .env file not found in the project root directory ($PROJECT_ROOT)"
    echo "Please copy .env.example to .env and configure it:"
    echo "  cp .env.example .env"
    exit 1
fi

# Source .env file
source "$PROJECT_ROOT/.env"

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
    error "This script must be run with sudo privileges."
fi

# Check dependencies
check_dependencies() {
    log "Checking dependencies"
    
    for cmd in shasum systemctl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "Installing $cmd..."
            apt-get update -qq && apt-get install -qq -y "$cmd" || error "Failed to install $cmd"
        fi
    done
}

# Install hBlock
install_hblock() {
    log "Installing hBlock ${HBLOCK_VERSION}"
    
    # Download and verify hBlock
    curl -o /tmp/hblock "https://raw.githubusercontent.com/hectorm/hblock/${HBLOCK_VERSION}/hblock" || \
        error "Failed to download hBlock"
    
    echo "${HBLOCK_BINARY_SHA}  /tmp/hblock" | shasum -c || error "SHA256 verification failed"
    
    # Install hBlock
    mv /tmp/hblock /usr/local/bin/hblock || error "Unable to move hBlock"
    chown 0:0 /usr/local/bin/hblock
    chmod 755 /usr/local/bin/hblock
    
    log "hBlock installed successfully"
}

# Install systemd services
install_systemd_services() {
    log "Installing systemd services"
    
    # Download service and timer files
    curl -o '/tmp/hblock.service' "https://raw.githubusercontent.com/hectorm/hblock/${HBLOCK_VERSION}/resources/systemd/hblock.service"
    curl -o '/tmp/hblock.timer' "https://raw.githubusercontent.com/hectorm/hblock/${HBLOCK_VERSION}/resources/systemd/hblock.timer"
    
    # Verify checksums
    echo "${HBLOCK_SERVICE_SHA}  /tmp/hblock.service" | shasum -c || error "SHA256 verification for service failed"
    echo "${HBLOCK_TIMER_SHA}  /tmp/hblock.timer" | shasum -c || error "SHA256 verification for timer failed"
    
    # Install systemd units
    mv /tmp/hblock.{service,timer} /etc/systemd/system/ || error "Unable to move systemd files"
    chown 0:0 /etc/systemd/system/hblock.{service,timer}
    chmod 644 /etc/systemd/system/hblock.{service,timer}
    
    # Reload and enable
    systemctl daemon-reload
    systemctl enable hblock.timer
    systemctl start hblock.timer
    
    log "Systemd services installed and enabled"
}

# Configure hBlock
configure_hblock() {
    log "Configuring hBlock"
    
    # Create configuration directory
    mkdir -p /etc/hblock
    
    # Configure block sources
    local sources=""
    for list in "${HBLOCK_LISTS[@]}"; do
        sources+="$list\n"
    done
    
    echo -e "$sources" > /etc/hblock/sources.list
    
    # Configure hBlock options
    cat > /etc/hblock/config << EOF
# hBlock configuration
ALLOW_REDIRECTIONS=true
BLOCK_MINING=true
VERIFY_SOURCES=true
EOF
    
    log "hBlock configuration completed"
}

# First run and verification
verify_hblock() {
    log "First run of hBlock"
    
    # Backup original hosts file
    if [ -f "/etc/hosts" ]; then
        log "Backing up original hosts file"
        cp /etc/hosts /etc/hosts.backup
    fi
    
    # Check for immutable attribute
    if lsattr /etc/hosts 2>/dev/null | grep -q '^....i'; then
        log "Removing immutable attribute from /etc/hosts"
        chattr -i /etc/hosts
    fi
    
    # Ensure file is writable
    chmod 644 /etc/hosts
    
    # Run hBlock
    log "Running hBlock..."
    if ! hblock; then
        error "hBlock execution failed"
    fi
    
    # Robust verification
    if ! grep -q "^0\.0\.0\.0" /etc/hosts; then
        # Display content for diagnosis
        log "Current /etc/hosts content:"
        cat /etc/hosts
        error "The hosts file was not updated correctly"
    fi
    
    log "hBlock is working correctly"
    log "Number of blocked domains: $(grep -c "^0\.0\.0\.0" /etc/hosts)"
}

# Show status
show_status() {
    log "hBlock installation completed"
    log "Installed version : ${HBLOCK_VERSION}"
    log "Automatic update : ${HBLOCK_UPDATE_FREQUENCY}"
    log "Number of blocklists : ${#HBLOCK_LISTS[@]}"
    
    # Show next update schedule
    NEXT_UPDATE=$(systemctl show hblock.timer --property=NextElapseUSecRealtime | cut -d= -f2)
    if [ -n "$NEXT_UPDATE" ]; then
        log "Next update : $NEXT_UPDATE"
    fi
}

# Main execution
main() {
    section "Installation and Configuration of hBlock"
    log "Starting hBlock installation"
    check_dependencies
    install_hblock
    install_systemd_services
    configure_hblock
    verify_hblock
    show_status
    log "hBlock installation completed successfully"
}

# Script entry point
main
#!/bin/bash
set -euo pipefail

# 99-final-script.sh: Securing and finalizing parental control
# To be executed as root after all other scripts

# Common utility functions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    error "This script must be run with root privileges (sudo)"
fi

# Get the project root directory (where .env should be)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load environment variables
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo "Error: .env file not found in the project root directory ($PROJECT_ROOT)"
    echo "Please copy .env.example to .env and configure it:"
    echo "  cp .env.example .env"
    exit 1
fi

source "$PROJECT_ROOT/.env"

log "Starting final security phase."

# 1. Check permissions on scripts and logs
section "System Security Verification"
log "Checking permissions on sensitive scripts and logs"
chmod 700 /usr/local/bin/internet-quota.sh
if [ -f /usr/local/bin/.env.quota ]; then
    chmod 600 /usr/local/bin/.env.quota
    chown root:root /usr/local/bin/.env.quota
fi
chown root:root /usr/local/bin/internet-quota.sh

# 2. Final hardening
section "Final System Hardening"
log "Starting final hardening phase..."

# 2a. Secure quota configuration
if [ -f /usr/local/bin/.env.quota ]; then
    chmod 600 /usr/local/bin/.env.quota
    chown root:root /usr/local/bin/.env.quota
fi

# 2b. Ask user about script removal
read -p "Do you want to remove installation scripts and .env file? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Remove installation scripts
    log "Removing installation scripts from $PROJECT_ROOT"
    rm -f "$PROJECT_ROOT"/scripts/0*-*.sh "$PROJECT_ROOT"/scripts/99-final-script.sh
    
    # Remove .env file
    log "Removing .env file from $PROJECT_ROOT"
    rm -f "$PROJECT_ROOT/.env"
    
    log "Hardening complete: Installation scripts and .env file removed"
else
    log "Hardening skipped: Installation scripts and .env file preserved"
fi

# 3. Remove child user from sudo group (moved to end)
if id -nG "$CHILD_USERNAME" | grep -qw sudo; then
    log "Removing $CHILD_USERNAME from sudo group"
    deluser "$CHILD_USERNAME" sudo
else
    log "$CHILD_USERNAME is not in sudo group."
fi

# 4. (Optional) Restart machine
read -p "Restart machine now? [y/N] " answer
answer=${answer:-N}
if [[ "$answer" =~ ^[yY]$ ]]; then
    log "Restarting..."
    reboot
else
    log "Restart cancelled. Remember to restart manually to apply all restrictions."
fi

log "Final security phase completed."

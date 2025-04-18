#!/bin/bash
set -euo pipefail

# 99-final-script.sh: Securing and finalizing parental control
# To be executed as root after all other scripts

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    error "This script must be run with root privileges (sudo)"
fi

# Load configuration
if [ ! -f ".env" ]; then
    error ".env file not found in current directory."
fi
source .env

log "Starting final security phase."

# 1. Remove child user from sudo group
if id -nG "$CHILD_USERNAME" | grep -qw sudo; then
    log "Removing $CHILD_USERNAME from sudo group"
    deluser "$CHILD_USERNAME" sudo
else
    log "$CHILD_USERNAME is not in sudo group."
fi

# 2. Check permissions on scripts and logs
log "Checking permissions on sensitive scripts and logs"
chmod 700 /usr/local/bin/internet-quota.sh
if [ -f /usr/local/bin/.env.quota ]; then
    chmod 600 /usr/local/bin/.env.quota
    chown root:root /usr/local/bin/.env.quota
fi
chown root:root /usr/local/bin/internet-quota.sh

# 2b. Automatic removal of installation scripts and .env
log "Automatic removal of installation scripts and .env in $(pwd)"
rm -f 0*-*.sh 99-final-script.sh .env
log "Cleanup completed."

# 3. (Optional) Restart machine
read -p "Restart machine now? [y/N] " answer
answer=${answer:-N}
if [[ "$answer" =~ ^[yY]$ ]]; then
    log "Restarting..."
    reboot
else
    log "Restart cancelled. Remember to restart manually to apply all restrictions."
fi

log "Final security phase completed."

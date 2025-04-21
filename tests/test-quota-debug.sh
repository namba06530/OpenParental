#!/bin/bash
set -euo pipefail

# Common utility functions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN]${NC} $1" >&2
}

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source .env file
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    log_error "Configuration file not found at $PROJECT_ROOT/.env"
    exit 1
fi
source "$PROJECT_ROOT/.env"

# Check required commands
for cmd in iptables notify-send; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "$cmd is not installed"
        exit 1
    fi
done

# Check quota script
if [ ! -f "/usr/local/bin/internet-quota.sh" ]; then
    log_error "Quota script not found"
    exit 1
fi

if [ ! -x "/usr/local/bin/internet-quota.sh" ]; then
    log_error "Quota script is not executable"
    exit 1
fi

# Check quota directory
if [ ! -d "/var/lib/openparental/quota" ]; then
    log_error "Quota directory not found"
    exit 1
fi

if [ ! -w "/var/lib/openparental/quota" ]; then
    log_error "Quota directory is not writable"
    exit 1
fi

# Check quota file
quota_file="/var/lib/openparental/quota/${CHILD_USERNAME}.log"
if [ ! -f "$quota_file" ]; then
    log_warn "Quota file not found, creating it"
    echo "0" > "$quota_file"
    chmod 600 "$quota_file"
    chown "$CHILD_USERNAME:$CHILD_USERNAME" "$quota_file"
fi

if [ ! -w "$quota_file" ]; then
    log_error "Quota file is not writable"
    exit 1
fi

# Check iptables rules
if ! iptables -L QUOTA_TIME >/dev/null 2>&1; then
    log_error "QUOTA_TIME chain not found"
    exit 1
fi

if ! iptables -L WHITELIST >/dev/null 2>&1; then
    log_error "WHITELIST chain not found"
    exit 1
fi

# Test quota functionality
log "Testing quota functionality..."

# Test reset
if ! /usr/local/bin/internet-quota.sh reset; then
    log_error "Quota reset failed"
    exit 1
fi

# Test tracking
if ! /usr/local/bin/internet-quota.sh track; then
    log_error "Quota tracking failed"
    exit 1
fi

# Test status
if ! /usr/local/bin/internet-quota.sh status; then
    log_error "Quota status failed"
    exit 1
fi

log "All tests passed successfully!" 
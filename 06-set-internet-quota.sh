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
warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN]${NC} $1" >&2
}
error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1" >&2
    exit 1
}

# Check for .env file presence
if [ ! -f ".env" ]; then
    error ".env file not found in current directory."
fi
source .env

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
    error "This script must be run with sudo privileges"
fi

# Dependencies installation (already done at the beginning of pipeline in script 00-install.sh)
# install_dependencies() {
    # log "Installing required dependencies (iptables, sqlite3, iproute2, libnotify-bin)"
    # apt install -y iptables sqlite3 iproute2 libnotify-bin || error "Failed to install dependencies"
# }

# Generate minimal .env for internet-quota.sh
create_minimal_env() {
    log "Generating minimal .env for internet-quota.sh (only necessary variables will be copied)"
    local minimal_env="/usr/local/bin/.env.quota"
    # List of required variables
    local vars=(
        QUOTA_DAILY_MINUTES
        QUOTA_START_TIME
        QUOTA_RESET_TIME
        CHILD_USERNAME
        QUOTA_SESSION_DIR
        WHITELIST_DOMAINS
    )
    > "$minimal_env"
    for var in "${vars[@]}"; do
        if grep -q "^$var=" .env; then
            grep "^$var=" .env >> "$minimal_env"
        fi
    done
    chmod 600 "$minimal_env"
}

# Copy quota management script and .env
install_quota_script() {
    log "Copying deploy/internet-quota.sh to /usr/local/bin/internet-quota.sh (to be done on child machine)"
    cp "$(dirname "$0")/deploy/internet-quota.sh" /usr/local/bin/internet-quota.sh
    chmod +x /usr/local/bin/internet-quota.sh
    create_minimal_env
}

# Create systemd services
create_systemd_services() {
    log "Creating systemd services for quota tracking and reset"
    # Tracking service
    cat > /etc/systemd/system/internet-quota-track.service << EOF
[Unit]
Description=Internet Time Quota Tracking
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/internet-quota.sh track
EOF
    # Timer for tracking (every minute)
    cat > /etc/systemd/system/internet-quota-track.timer << EOF
[Unit]
Description=Run Internet Time Quota Tracking Every Minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Unit=internet-quota-track.service

[Install]
WantedBy=timers.target
EOF
    # Reset service
    cat > /etc/systemd/system/internet-quota-reset.service << EOF
[Unit]
Description=Reset Internet Time Quota
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/internet-quota.sh reset
EOF
    # Reset timer (daily at defined time)
    cat > /etc/systemd/system/internet-quota-reset.timer << EOF
[Unit]
Description=Reset Internet Time Quota Daily

[Timer]
OnCalendar=*-*-* ${QUOTA_RESET_TIME}:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
    systemctl daemon-reload
    systemctl enable internet-quota-track.timer
    systemctl enable internet-quota-reset.timer
    systemctl start internet-quota-track.timer
    systemctl start internet-quota-reset.timer
    log "Systemd services created and activated."
}

main() {
    log "Starting Internet quota configuration (simplified mode)"
    # install_dependencies
    install_quota_script
    create_systemd_services
    log "Configuration completed."
    echo -e "\n${YELLOW}IMPORTANT:\n- The script /usr/local/bin/internet-quota.sh must be deployed on each child machine.\n- The .env file must be present in the same directory as the script on the child machine.\n- Systemd services are created to automate quota tracking and reset.\n- For any modifications, edit the script or .env then run this script again.\n${NC}"
}

main

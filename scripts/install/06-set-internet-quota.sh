#!/bin/bash
set -euo pipefail

# 06-set-internet-quota.sh: Configure internet quota tracking
# To be executed as root

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

# Get the project root directory (where .env should be)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load environment variables
if [ -f "../../.env" ]; then
    source "../../.env"
elif [ -f "../.env" ]; then
    source "../.env"
elif [ -f ".env" ]; then
    source ".env"
else
    echo "Error: .env file not found in the project root directory ($PWD)"
    echo "Please copy .env.example to .env and configure it:"
    echo "  cp .env.example .env"
    exit 1
fi

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
    error "This script must be run with sudo privileges"
fi

# Verify dependencies
verify_dependencies() {
    local deps=("iptables" "notify-send")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing required dependencies: ${missing[*]}"
    fi
}

# Verify directories
verify_directories() {
    local dirs=(
        "/var/log/openparental/quota"
        "/var/lib/openparental/quota"
        "/usr/local/bin/lib"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            chmod 700 "$dir"
            log "Created directory: $dir"
        fi
    done
}

# Generate minimal .env for internet-quota.sh (simplified version)
create_minimal_env() {
    log "Generating .env.quota for internet-quota.sh"
    local minimal_env="/usr/local/bin/.env.quota"
    
    # Create file with header
    cat > "$minimal_env" << EOF
# Internet Quota Configuration - Simplified Version
# ===============================================
# This file contains the configuration for the internet quota system.
# It is automatically generated during installation.

# Quota Settings
QUOTA_DAILY_MINUTES="${QUOTA_DAILY_MINUTES:-120}"            # Daily internet time limit in minutes

# Session Storage
QUOTA_SESSION_DIR="/var/lib/openparental/quota"  # Directory for quota session data

# User Configuration
CHILD_USERNAME="${CHILD_USERNAME:-child}"        # Username to monitor
EOF

    # Set proper permissions
    chmod 600 "$minimal_env"
    chown root:root "$minimal_env"
    
    log "Created $minimal_env with proper permissions"
}

# Copy quota management script and .env
install_quota_script() {
    log "Copying src/internet-quota.sh to /usr/local/bin/internet-quota.sh (to be done on child machine)"
    cp "$PROJECT_ROOT/src/internet-quota.sh" "/usr/local/bin/internet-quota.sh"
    chmod +x "/usr/local/bin/internet-quota.sh"

    # Copy library files
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Copying library files to /usr/local/bin/lib/"
    mkdir -p "/usr/local/bin/lib/"
    cp -r "$PROJECT_ROOT/src/lib/"*.sh "/usr/local/bin/lib/" 2>/dev/null || log "No library files found to copy"
    chmod +x "/usr/local/bin/lib/"*.sh 2>/dev/null || true

    create_minimal_env
}

# Create systemd services
create_systemd_services() {
    # Skip systemd operations in test mode
    if [ "${TEST_MODE:-false}" = "true" ]; then
        log "Test mode: Skipping systemd service creation"
        return 0
    fi

    log "Creating systemd services for quota tracking and reset"
    # Tracking service
    cat > /etc/systemd/system/internet-quota-track.service << EOF
[Unit]
Description=Internet Time Quota Tracking
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/internet-quota.sh track
User=root
Group=root

[Install]
WantedBy=multi-user.target
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
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    # Reset timer (daily at defined time)
    cat > /etc/systemd/system/internet-quota-reset.timer << EOF
[Unit]
Description=Reset Internet Time Quota Daily

[Timer]
OnCalendar=*-*-* ${QUOTA_RESET_TIME:-00:00}:00
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

# Initialize quota tracking file
initialize_quota_file() {
    local quota_dir="/var/lib/openparental/quota"
    local quota_file="$quota_dir/${CHILD_USERNAME}.log"
    
    # Create directory if it doesn't exist
    mkdir -p "$quota_dir"
    chmod 700 "$quota_dir"
    chown root:root "$quota_dir"
    
    # Create initial quota file if it doesn't exist
    if [ ! -f "$quota_file" ]; then
        log "Creating initial quota tracking file for $CHILD_USERNAME"
        echo "0" > "$quota_file"
        chmod 600 "$quota_file"
        chown "$CHILD_USERNAME:$CHILD_USERNAME" "$quota_file"
    fi
}

main() {
    section "Installation and Configuration of Internet Quota"
    log "Starting Internet Quota configuration"
    verify_dependencies
    verify_directories
    install_quota_script
    create_systemd_services
    initialize_quota_file
    log "Configuration completed."
    if [ "${TEST_MODE:-false}" != "true" ]; then
        echo -e "\n${YELLOW}IMPORTANT:\n- The script /usr/local/bin/internet-quota.sh must be deployed on each child machine.\n- The .env file must be present in the same directory as the script on the child machine.\n- Systemd services are created to automate quota tracking and reset.\n- For any modifications, edit the script or .env then run this script again.\n${NC}"
    fi
}

main

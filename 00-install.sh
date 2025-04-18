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

section() {
    echo -e "\n${BLUE}========== $1 ==========${NC}\n"
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

# Check working directory
if [ ! -f "00-install.sh" ]; then
    error "This script must be run from the ct_parent directory."
fi

# System prerequisites check
check_prerequisites() {
    section "Checking prerequisites..."
    # Check distribution
    if ! grep -q "Ubuntu" /etc/os-release; then
        error "This script requires Ubuntu."
    fi
    # Check required packages
    local required_packages=(
        "iptables"
        "sqlite3"
        "curl"
        "iproute2"
        "libnotify-bin"
    )
    local missing_packages=()
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            missing_packages+=("$package")
        fi
    done
    if [ ${#missing_packages[@]} -ne 0 ]; then
        log "Installing missing packages: ${missing_packages[*]}"
        apt update -qq
        apt install -qq -y "${missing_packages[@]}" || error "Unable to install required packages."
    fi
    log "All prerequisites are satisfied."
}

# Run a script
run_script() {
    local script=$1
    local name=$2
    section "$name"
    if [ ! -f "$script" ]; then
        error "Script not found: $script"
    fi
    chmod +x "$script"
    if ! bash "$script"; then
        error "Failed to execute $script"
    fi
    log "$name completed successfully."
}

# Main execution
main() {
    clear
    TITLE_COLOR='\033[1;36m'
    NC='\033[0m'
    echo -e "${TITLE_COLOR}"
    echo    "==============================================================="
    echo    "           OpenParental v0.1 - Installation Pipeline          "
    echo    "==============================================================="
    echo -e "${NC}\n"
    sleep 1
    # 1. Set timezone (interactive)
    # section "Timezone configuration (tzdata)"
    sleep 1
    # dpkg-reconfigure tzdata
    # 2. System update
    section "System update..."
    apt update -qq
    apt upgrade -qq -y
    echo
    # 3. Install antivirus (ClamAV)
    section "ClamAV antivirus installation..."
    apt install -qq -y clamav clamav-daemon
    systemctl enable clamav-freshclam && systemctl start clamav-freshclam
    echo
    # Source .env file
    source .env
    # Prerequisites check
    check_prerequisites
    echo
    # Run scripts in order
    scripts=(
        "01-create-hidden-admin-user.sh:Admin account creation..."
        "02-install-and-configure-ssh.sh:SSH installation and configuration..."
        "03-force-custom-dns.sh:Secure DNS configuration..."
        "04-install-and-configure-hblock.sh:hBlock installation and configuration..."
        "05-install-and-configure-Timekpr.sh:Timekpr installation and configuration..."
        "06-set-internet-quota.sh:Internet quota configuration..."
        "99-final-script.sh:Final hardening..."
    )
    for entry in "${scripts[@]}"; do
        script="${entry%%:*}"
        name="${entry#*:}"
        run_script "$script" "$name"
        sleep 1
    done
    section "Installation complete"
    echo -e "${GREEN}OpenParental v0.1 installation completed successfully!${NC}\n"
    log "Admin user: $ADMIN_USERNAME"
    log "Child user: $CHILD_USERNAME"
    log "Internet quota: $QUOTA_DAILY_MINUTES minutes per day"
    log "Screen time: $TIMEKPR_DAILY_LIMIT_SECONDS seconds per day"
    echo -e "\n${YELLOW}You can now reboot the machine to apply all changes.${NC}\n"
}

# Error handling
set -e
trap 'error "An error occurred during installation"' ERR

# Script entry point
main
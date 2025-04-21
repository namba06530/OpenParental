#!/bin/bash
set -euo pipefail

# 00-install.sh: Main installation script for OpenParental
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
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    error "This script must be run with sudo privileges"
fi

# Verify dependencies
verify_dependencies() {
    local deps=("apt" "systemctl" "iptables" "notify-send")
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
        "/var/log/openparental"
        "/var/lib/openparental"
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

# Install dependencies
install_dependencies() {
    log "Installing required dependencies"
    apt update
    apt install -y iptables sqlite3 iproute2 libnotify-bin curl || error "Failed to install dependencies"
}

# Copy source files
copy_source_files() {
    log "Copying source files"
    cp -r "$PROJECT_ROOT/src/"* /usr/local/bin/
    chmod 755 /usr/local/bin/internet-quota.sh
    chmod 600 /usr/local/bin/lib/*.sh
}

# Execute installation scripts in order
execute_scripts() {
    local scripts=(
        "01-create-hidden-admin-user.sh"
        "02-install-and-configure-ssh.sh"
        "03-force-custom-dns.sh"
        "04-install-and-configure-hblock.sh"
        "05-install-and-configure-Timekpr.sh"
        "06-set-internet-quota.sh"
    )
    
    for script in "${scripts[@]}"; do
        echo -e "\n${BLUE}=================================================${NC}"
        echo -e "${BLUE}           Executing $script${NC}"
        echo -e "${BLUE}=================================================${NC}\n"
        if ! bash "$PROJECT_ROOT/scripts/install/$script"; then
            error "Failed to execute $script"
        fi
    done
}

# Final security phase
final_security() {
    echo -e "\n${BLUE}=================================================${NC}"
    echo -e "${BLUE}           Final Security Phase${NC}"
    echo -e "${BLUE}=================================================${NC}\n"
    log "Starting final security phase"
    if ! bash "$PROJECT_ROOT/scripts/install/99-final-script.sh"; then
        error "Failed to execute final security script"
    fi
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

    # System update
    section "System update..."
    apt update -qq
    apt upgrade -qq -y
    echo

    # Install antivirus (ClamAV)
    section "ClamAV antivirus installation..."
    apt install -qq -y clamav clamav-daemon
    systemctl enable clamav-freshclam && systemctl start clamav-freshclam
    echo

    # Prerequisites check
    verify_dependencies
    verify_directories
    install_dependencies
    copy_source_files
    execute_scripts
    final_security

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
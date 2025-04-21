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

# Installing Timekpr-nExT
install_timekpr() {
    log "Installing Timekpr-nExT"
    
    # Adding PPA repository
    if ! add-apt-repository -y ppa:mjasnik/ppa; then
        error "Unable to add Timekpr PPA"
    fi
    
    # Update packages (unnecessary, already done at pipeline start)
    apt update -qq || error "Failed to update packages"
    
    # Install Timekpr
    apt install -qq -y timekpr-next || error "Failed to install Timekpr"
    
    log "Timekpr-nExT installed successfully"
}

# Basic Timekpr configuration
configure_timekpr() {
    log "Configuring Timekpr for user $CHILD_USERNAME"
    
    # Check if user exists
    if ! id "$CHILD_USERNAME" >/dev/null 2>&1; then
        error "User $CHILD_USERNAME does not exist"
    fi
    
    # Set allowed days
    if ! timekpra --setalloweddays "$CHILD_USERNAME" "$TIMEKPR_WORK_DAYS"; then
        error "Unable to configure allowed days"
    fi
    
    # Set allowed hours
    if ! timekpra --setallowedhours "$CHILD_USERNAME" "ALL" "$TIMEKPR_ALLOWED_HOURS"; then
        error "Unable to configure allowed hours"
    fi
    
    # Set daily limits    
    if ! timekpra --settimelimits "$CHILD_USERNAME" "$TIMEKPR_DAILY_LIMIT_SECONDS"; then
        error "Unable to configure daily limits"
    fi
    
    # Set weekly limit
    if ! timekpra --settimelimitweek "$CHILD_USERNAME" "$TIMEKPR_WEEKLY_LIMIT_SECONDS"; then
        error "Unable to configure weekly limit"
    fi

    # Set monthly limit
    if ! timekpra --settimelimitmonth "$CHILD_USERNAME" "$TIMEKPR_MONTHLY_LIMIT_SECONDS"; then
        error "Unable to configure monthly limit"
    fi
    
    log "Basic configuration completed"
}

# Advanced configuration
configure_advanced_settings() {
    log "Configuring advanced settings"
    
    # Configure logout type
    if ! timekpra --setlockouttype "$CHILD_USERNAME" "$TIMEKPR_AUTO_LOGOUT"; then
        error "Unable to configure logout type"
    fi
    
    # Configure inactivity tracking
    if ! timekpra --settrackinactive "$CHILD_USERNAME" "$TIMEKPR_TRACK_INACTIVITY"; then
        error "Unable to configure inactivity tracking"
    fi
    
    # Configure taskbar icon
    if ! timekpra --sethidetrayicon "$CHILD_USERNAME" "$TIMEKPR_HIDE_TRAY"; then
        error "Unable to configure tray icon"
    fi
    
    log "Advanced configuration completed"
}

# Configuration verification
verify_configuration() {
    log "Verifying configuration"
    
    # Check if service is active
    if ! systemctl is-active --quiet timekpr.service; then
        error "Timekpr service is not active"
    fi
    
    # Get and verify user information
    if ! timekpra --userinfo "$CHILD_USERNAME" | grep -q "LIMITS_PER_WEEKDAYS: $TIMEKPR_DAILY_LIMIT_SECONDS"; then
        warn "Daily limit might not be properly configured"
    fi
    
    log "Configuration verified successfully"
}

# Display status
show_status() {
    log "Timekpr configuration completed"
    log "Configured user: $CHILD_USERNAME"
    log "Daily limit: $TIMEKPR_DAILY_LIMIT_SECONDS seconds"
    log "Access hours: $TIMEKPR_START_TIME - $TIMEKPR_END_TIME"
    
    # Show complete configuration
    timekpra --userinfo "$CHILD_USERNAME"
}

# Main execution
main() {
    section "Installation and Configuration of Timekpr"
    log "Starting Timekpr installation and configuration"
    install_timekpr
    configure_timekpr
    configure_advanced_settings
    verify_configuration
    show_status
    log "Timekpr installation and configuration completed successfully"
}

# Launch script
main
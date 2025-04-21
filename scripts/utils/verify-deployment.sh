#!/bin/bash
set -euo pipefail

# Common utility functions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN]${NC} $1" >&2
}

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source .env file
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    log_error "Configuration file not found at $PROJECT_ROOT/.env"
    exit 1
fi
source "$PROJECT_ROOT/.env"

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run with sudo privileges"
    exit 1
fi

# Check required commands
check_commands() {
    echo -e "\nChecking required commands..."
    for cmd in iptables notify-send; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_success "$cmd is installed"
        else
            log_error "$cmd is not installed"
            return 1
        fi
    done
}

# Check directory structure
check_directories() {
    echo -e "\nChecking directory structure..."
    local dirs=(
        "/var/log/openparental"
        "/var/lib/openparental"
        "/usr/local/bin/lib"
    )
    
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            log_success "Directory exists: $dir"
            if [ -w "$dir" ]; then
                log_success "Directory is writable: $dir"
            else
                log_error "Directory is not writable: $dir"
                return 1
            fi
        else
            log_error "Directory does not exist: $dir"
            return 1
        fi
    done
}

# Check quota configuration
check_quota() {
    echo -e "\nChecking quota configuration..."
    
    # Check quota script
    if [ -f "/usr/local/bin/internet-quota.sh" ]; then
        log_success "Quota script exists"
        if [ -x "/usr/local/bin/internet-quota.sh" ]; then
            log_success "Quota script is executable"
        else
            log_error "Quota script is not executable"
            return 1
        fi
    else
        log_error "Quota script not found"
        return 1
    fi
    
    # Check quota file
    local quota_file="/var/lib/openparental/quota/${CHILD_USERNAME}.log"
    if [ -f "$quota_file" ]; then
        log_success "Quota file exists"
        if [ -w "$quota_file" ]; then
            log_success "Quota file is writable"
        else
            log_error "Quota file is not writable"
            return 1
        fi
    else
        log_error "Quota file not found"
        return 1
    fi
}

# Check systemd services
check_services() {
    echo -e "\nChecking systemd services..."
    local services=(
        "internet-quota-track.service"
        "internet-quota-reset.service"
    )
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log_success "Service is running: $service"
        else
            log_error "Service is not running: $service"
            return 1
        fi
    done
}

# Check iptables rules
check_iptables() {
    echo -e "\nChecking iptables rules..."
    if iptables -L QUOTA_TIME >/dev/null 2>&1; then
        log_success "QUOTA_TIME chain exists"
    else
        log_error "QUOTA_TIME chain not found"
        return 1
    fi
    
    if iptables -L WHITELIST >/dev/null 2>&1; then
        log_success "WHITELIST chain exists"
    else
        log_error "WHITELIST chain not found"
        return 1
    fi
}

# Main execution
main() {
    echo -e "\nStarting deployment verification..."
    
    local checks=(
        "check_commands"
        "check_directories"
        "check_quota"
        "check_services"
        "check_iptables"
    )
    
    local failed=0
    for check in "${checks[@]}"; do
        if ! $check; then
            failed=1
        fi
    done
    
    if [ $failed -eq 0 ]; then
        echo -e "\n${GREEN}All checks passed successfully!${NC}"
    else
        echo -e "\n${RED}Some checks failed. Please review the errors above.${NC}"
        exit 1
    fi
}

main 
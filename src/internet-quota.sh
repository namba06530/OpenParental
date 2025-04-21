#!/bin/bash
set -euo pipefail

# internet-quota.sh - Main script for internet quota management
# This script integrates all modules into a unified system

# Set script directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load all modules
MODULES_DIR="${SCRIPT_DIR}/modules"
if [ -d "$MODULES_DIR" ]; then
    # Load modules from local directory
    source "${MODULES_DIR}/quota-config.sh" 2>/dev/null || true
    source "${MODULES_DIR}/quota-core.sh" 2>/dev/null || true
    source "${MODULES_DIR}/quota-security.sh" 2>/dev/null || true
    source "${MODULES_DIR}/quota-network.sh" 2>/dev/null || true
elif [ -d "/usr/local/bin/modules" ]; then
    # Load modules from system directory
    source "/usr/local/bin/modules/quota-config.sh" 2>/dev/null || true
    source "/usr/local/bin/modules/quota-core.sh" 2>/dev/null || true
    source "/usr/local/bin/modules/quota-security.sh" 2>/dev/null || true
    source "/usr/local/bin/modules/quota-network.sh" 2>/dev/null || true
fi

# Load common libraries
if [ -f "${SCRIPT_DIR}/lib/logging.sh" ]; then
    source "${SCRIPT_DIR}/lib/logging.sh"
elif [ -f "/usr/local/bin/lib/logging.sh" ]; then
    source "/usr/local/bin/lib/logging.sh"
fi

if [ -f "${SCRIPT_DIR}/lib/error-handling.sh" ]; then
    source "${SCRIPT_DIR}/lib/error-handling.sh"
elif [ -f "/usr/local/bin/lib/error-handling.sh" ]; then
    source "/usr/local/bin/lib/error-handling.sh"
fi

# Simple logging fallback if libraries are not available
if ! command -v log_info &>/dev/null; then
    log_info() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"
    }
    log_error() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2
    }
}

# Initialize logging
LOG_MODULE="internet-quota"
log_info "$LOG_MODULE" "system" "Starting internet quota system"

# Check for module availability
if ! command -v quota_track &>/dev/null; then
    log_error "$LOG_MODULE" "system" "Required modules not loaded"
    echo "Error: Required modules could not be loaded."
    echo "Please check your installation."
    exit 1
fi

# Parse command line arguments
if [ "$#" -lt 1 ]; then
    log_error "$LOG_MODULE" "system" "Missing command argument"
    echo "Usage: $0 {track|reset|status|config|network}"
    exit 1
fi

# Process commands
case "$1" in
    "track")
        log_info "$LOG_MODULE" "system" "Executing quota tracking"
        if [ -n "${2:-}" ]; then
            quota_track "$2"
        else
            quota_track
        fi
        ;;
    "reset")
        log_info "$LOG_MODULE" "system" "Executing quota reset"
        if [ -n "${2:-}" ]; then
            quota_reset "$2"
        else
            quota_reset
        fi
        ;;
    "status")
        log_info "$LOG_MODULE" "system" "Checking quota status"
        if [ -n "${2:-}" ]; then
            quota_status "$2"
        else
            quota_status
        fi
        ;;
    "config")
        # Configuration management subcommands
        if [ "$#" -lt 2 ]; then
            log_error "$LOG_MODULE" "system" "Missing config subcommand"
            echo "Usage: $0 config {show|validate|generate}"
            exit 1
        fi
        
        case "$2" in
            "show")
                log_info "$LOG_MODULE" "system" "Displaying configuration"
                config_display
                ;;
            "validate")
                log_info "$LOG_MODULE" "system" "Validating configuration"
                config_validate
                ;;
            "generate")
                log_info "$LOG_MODULE" "system" "Generating config file"
                if [ -n "${3:-}" ]; then
                    config_generate_env "$3"
                else
                    config_generate_env
                fi
                ;;
            *)
                log_error "$LOG_MODULE" "system" "Invalid config subcommand: $2"
                echo "Usage: $0 config {show|validate|generate}"
                exit 1
                ;;
        esac
        ;;
    "network")
        # Network management subcommands
        if [ "$#" -lt 2 ]; then
            log_error "$LOG_MODULE" "system" "Missing network subcommand"
            echo "Usage: $0 network {setup|block|allow|whitelist|cleanup}"
            exit 1
        fi
        
        case "$2" in
            "setup")
                log_info "$LOG_MODULE" "system" "Setting up network rules"
                network_setup_chains
                ;;
            "block")
                if [ "$#" -lt 3 ]; then
                    log_error "$LOG_MODULE" "system" "Missing username parameter"
                    echo "Usage: $0 network block <username>"
                    exit 1
                fi
                log_info "$LOG_MODULE" "system" "Blocking internet for user $3"
                network_control_access "$3" "" "block"
                ;;
            "allow")
                if [ "$#" -lt 3 ]; then
                    log_error "$LOG_MODULE" "system" "Missing username parameter"
                    echo "Usage: $0 network allow <username>"
                    exit 1
                fi
                log_info "$LOG_MODULE" "system" "Allowing internet for user $3"
                network_control_access "$3" "" "allow"
                ;;
            "whitelist")
                if [ "$#" -lt 3 ]; then
                    log_error "$LOG_MODULE" "system" "Missing domain parameter"
                    echo "Usage: $0 network whitelist <domain>"
                    exit 1
                fi
                log_info "$LOG_MODULE" "system" "Adding domain to whitelist: $3"
                network_add_whitelist "$3"
                ;;
            "cleanup")
                log_info "$LOG_MODULE" "system" "Cleaning up network rules"
                network_cleanup
                ;;
            *)
                log_error "$LOG_MODULE" "system" "Invalid network subcommand: $2"
                echo "Usage: $0 network {setup|block|allow|whitelist|cleanup}"
                exit 1
                ;;
        esac
        ;;
    "security")
        # Security management subcommands
        if [ "$#" -lt 2 ]; then
            log_error "$LOG_MODULE" "system" "Missing security subcommand"
            echo "Usage: $0 security {check|fix|checksum}"
            exit 1
        fi
        
        case "$2" in
            "check")
                log_info "$LOG_MODULE" "system" "Checking security"
                if [ -n "${3:-}" ]; then
                    security_check_permissions "$QUOTA_SESSION_DIR" "$3"
                else
                    security_check_permissions
                fi
                ;;
            "fix")
                log_info "$LOG_MODULE" "system" "Fixing security issues"
                if [ -n "${3:-}" ]; then
                    security_fix_permissions "$QUOTA_SESSION_DIR" "$3"
                else
                    security_fix_permissions
                fi
                ;;
            "checksum")
                if [ "$#" -lt 3 ]; then
                    log_error "$LOG_MODULE" "system" "Missing filename parameter"
                    echo "Usage: $0 security checksum {store|verify} <filename>"
                    exit 1
                fi
                
                if [ "$3" = "store" ]; then
                    if [ -n "${4:-}" ]; then
                        security_store_checksum "$4"
                    else
                        log_error "$LOG_MODULE" "system" "Missing filename parameter"
                        echo "Usage: $0 security checksum store <filename>"
                        exit 1
                    fi
                elif [ "$3" = "verify" ]; then
                    if [ -n "${4:-}" ]; then
                        security_verify_checksum "$4"
                    else
                        log_error "$LOG_MODULE" "system" "Missing filename parameter"
                        echo "Usage: $0 security checksum verify <filename>"
                        exit 1
                    fi
                else
                    log_error "$LOG_MODULE" "system" "Invalid checksum subcommand: $3"
                    echo "Usage: $0 security checksum {store|verify} <filename>"
                    exit 1
                fi
                ;;
            *)
                log_error "$LOG_MODULE" "system" "Invalid security subcommand: $2"
                echo "Usage: $0 security {check|fix|checksum}"
                exit 1
                ;;
        esac
        ;;
    *)
        log_error "$LOG_MODULE" "system" "Invalid command: $1"
        echo "Usage: $0 {track|reset|status|config|network|security}"
        exit 1
        ;;
esac

log_info "$LOG_MODULE" "system" "Script completed successfully"
exit 0

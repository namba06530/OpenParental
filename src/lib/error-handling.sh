#!/bin/bash
set -euo pipefail

# Global variables
declare -r ERROR_LOG_FILE="/var/log/openparental/quota/errors.log"
declare -r ERROR_TYPES=(
    "PERMISSION"
    "CONFIG"
    "NETWORK"
    "CRYPTO"
    "QUOTA"
    "SYSTEM"
)

# Standardized error codes
declare -A ERROR_CODES=(
    [E_CONFIG]=1      # Configuration error
    [E_PERMISSION]=2  # Permission error
    [E_DEPENDENCY]=3  # Missing dependency
    [E_SYSTEM]=4      # System error
    [E_NETWORK]=5     # Network error
    [E_CRYPTO]=6      # Encryption error
    [E_QUOTA]=7       # Quota error
    [E_UNKNOWN]=99    # Unknown error
)

# Error logging function
log_error() {
    local error_type="$1"
    local error_message="$2"
    local error_code="${3:-1}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Error type verification
    if ! [[ " ${ERROR_TYPES[@]} " =~ " ${error_type} " ]]; then
        error_type="SYSTEM"
    fi
    
    # Log to file
    echo "[${timestamp}] [${error_type}] [${error_code}] ${error_message}" >> "$ERROR_LOG_FILE"
    
    # Log to console
    echo "❌ [${error_type}] ${error_message}" >&2
    
    return "$error_code"
}

# Main error handling function
handle_error() {
    local error_code=$1
    local error_message=$2
    local error_context=$3
    local cleanup_function=$4

    # Error logging
    log_error "SYSTEM" "Code: $error_code - $error_message (Context: $error_context)"

    # Execute cleanup function if provided
    if [ -n "$cleanup_function" ] && type "$cleanup_function" >/dev/null 2>&1; then
        $cleanup_function
    fi

    # Exit with appropriate error code
    exit "${ERROR_CODES[$error_code]:-${ERROR_CODES[E_UNKNOWN]}}"
}

# Permission error handling
handle_permission_error() {
    local operation="$1"
    local target="$2"
    local user="${3:-$(whoami)}"
    
    log_error "PERMISSION" "Access denied for operation '${operation}' on '${target}' by user '${user}'"
    return 1
}

# Permission verification
check_permissions() {
    local required_user=$1
    local current_user=$(id -u)

    if [ "$current_user" != "$required_user" ]; then
        handle_error "E_PERMISSION" \
            "Insufficient permissions. Required user: $required_user" \
            "Permission verification" \
            ""
    fi
}

# Configuration error handling
handle_config_error() {
    local config_file="$1"
    local error_message="$2"
    
    if [ ! -f "$config_file" ]; then
        log_error "CONFIG" "Missing configuration file: ${config_file}"
        return 1
    fi
    
    log_error "CONFIG" "Configuration error in ${config_file}: ${error_message}"
    return 1
}

# Configuration verification
check_config() {
    local config_file=$1
    local required_vars=("${@:2}")

    if [ ! -f "$config_file" ]; then
        handle_error "E_CONFIG" \
            "Configuration file not found: $config_file" \
            "Configuration verification" \
            ""
    fi

    for var in "${required_vars[@]}"; do
        if ! grep -q "^$var=" "$config_file"; then
            handle_error "E_CONFIG" \
                "Missing configuration variable: $var" \
                "Configuration verification" \
                ""
        fi
    done
}

# Network error handling
handle_network_error() {
    local operation="$1"
    local target="$2"
    local error_message="$3"
    
    log_error "NETWORK" "Network error during ${operation} on ${target}: ${error_message}"
    return 1
}

# Cryptographic error handling
handle_crypto_error() {
    local operation="$1"
    local error_message="$2"
    
    log_error "CRYPTO" "Cryptographic error during ${operation}: ${error_message}"
    return 1
}

# Quota error handling
handle_quota_error() {
    local user="$1"
    local operation="$2"
    local error_message="$3"
    
    log_error "QUOTA" "Quota error for user ${user} during ${operation}: ${error_message}"
    return 1
}

# System error handling
handle_system_error() {
    local operation="$1"
    local error_message="$2"
    
    log_error "SYSTEM" "System error during ${operation}: ${error_message}"
    return 1
}

# Error cleanup function
cleanup_on_error() {
    local error_code="$1"
    local cleanup_commands=("${@:2}")
    
    for cmd in "${cleanup_commands[@]}"; do
        if ! eval "$cmd"; then
            log_error "SYSTEM" "Cleanup failed: ${cmd}"
        fi
    done
    
    return "$error_code"
}

# Temporary file cleanup
cleanup_temp_files() {
    local temp_files=("$@")
    
    for file in "${temp_files[@]}"; do
        if [ -e "$file" ]; then
            rm -f "$file"
            log_error "SYSTEM" "Temporary file deleted: $file"
        fi
    done
}

# Error trap handler
setup_error_handler() {
    local cleanup_commands=("$@")
    
    trap 'cleanup_on_error $? "${cleanup_commands[@]}"' ERR
    trap 'cleanup_on_error 0 "${cleanup_commands[@]}"' EXIT
}

# Prerequisites verification
check_prerequisites() {
    local missing_deps=()
    
    # Check for required commands
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Report missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "DEPENDENCY" "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# Export functions
export -f log_error handle_error handle_permission_error check_permissions
export -f handle_config_error check_config handle_network_error handle_crypto_error
export -f handle_quota_error handle_system_error cleanup_on_error cleanup_temp_files
export -f setup_error_handler check_prerequisites 
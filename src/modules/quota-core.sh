#!/bin/bash
# quota-core.sh - Core module for internet quota system
# Provides the main functionality for tracking and managing internet quotas

# Import required modules
if [ -f "$(dirname "${BASH_SOURCE[0]}")/quota-logging.sh" ]; then
    # shellcheck source=./quota-logging.sh
    . "$(dirname "${BASH_SOURCE[0]}")/quota-logging.sh"
else
    echo "ERROR: Required module quota-logging.sh not found" >&2
    exit 1
fi

if [ -f "$(dirname "${BASH_SOURCE[0]}")/quota-security.sh" ]; then
    # shellcheck source=./quota-security.sh
    . "$(dirname "${BASH_SOURCE[0]}")/quota-security.sh"
else
    echo "ERROR: Required module quota-security.sh not found" >&2
    exit 1
fi

if [ -f "$(dirname "${BASH_SOURCE[0]}")/quota-config.sh" ]; then
    # shellcheck source=./quota-config.sh
    . "$(dirname "${BASH_SOURCE[0]}")/quota-config.sh"
else
    echo "ERROR: Required module quota-config.sh not found" >&2
    exit 1
fi

# Default values
QUOTA_DATA_DIR=${QUOTA_DATA_DIR:-"/var/lib/internet-quota"}
QUOTA_FILE="${QUOTA_DATA_DIR}/quota.dat"
QUOTA_LOCK_FILE="${QUOTA_DATA_DIR}/quota.lock"

# Initialize core module
core_init() {
    log_info "Initializing core module"
    
    # Make sure security module is initialized
    if ! security_check_root && ! security_check_sudo; then
        log_error "This script must be run as root or with sudo privileges"
        return 1
    fi
    
    # Create data directory if it doesn't exist
    security_init_data_dir "$QUOTA_DATA_DIR" || {
        log_error "Failed to initialize data directory: $QUOTA_DATA_DIR"
        return 1
    }
    
    # Create quota file if it doesn't exist
    if [ ! -f "$QUOTA_FILE" ]; then
        if ! security_create_file "$QUOTA_FILE" "0640" "root" "root" "0"; then
            log_error "Failed to create quota file: $QUOTA_FILE"
            return 1
        fi
    fi
    
    log_info "Core module initialized successfully"
    return 0
}

# Acquire lock for quota operations
core_acquire_lock() {
    local timeout=${1:-10}  # Default timeout: 10 seconds
    local start_time
    local current_time
    
    start_time=$(date +%s)
    
    log_debug "Attempting to acquire lock: $QUOTA_LOCK_FILE (timeout: ${timeout}s)"
    
    # Try to create lock file
    while true; do
        if mkdir "$QUOTA_LOCK_FILE" 2>/dev/null; then
            # Lock acquired
            log_debug "Lock acquired: $QUOTA_LOCK_FILE"
            return 0
        fi
        
        # Check if lock is stale (older than 5 minutes)
        if [ -d "$QUOTA_LOCK_FILE" ]; then
            local lock_time
            lock_time=$(stat -c %Y "$QUOTA_LOCK_FILE" 2>/dev/null)
            local current_time
            current_time=$(date +%s)
            
            if [ $((current_time - lock_time)) -gt 300 ]; then
                log_warning "Removing stale lock: $QUOTA_LOCK_FILE"
                rmdir "$QUOTA_LOCK_FILE" 2>/dev/null
                continue
            fi
        fi
        
        # Check timeout
        current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge "$timeout" ]; then
            log_error "Lock acquisition timed out after ${timeout}s: $QUOTA_LOCK_FILE"
            return 1
        fi
        
        # Wait a bit before retrying
        sleep 0.5
    done
}

# Release lock for quota operations
core_release_lock() {
    if [ -d "$QUOTA_LOCK_FILE" ]; then
        log_debug "Releasing lock: $QUOTA_LOCK_FILE"
        rmdir "$QUOTA_LOCK_FILE" 2>/dev/null || {
            log_warning "Failed to release lock: $QUOTA_LOCK_FILE"
            return 1
        }
    else
        log_warning "No lock found to release: $QUOTA_LOCK_FILE"
        return 1
    fi
    
    return 0
}

# Get current quota usage
core_get_quota() {
    local usage
    
    log_debug "Reading current quota usage from: $QUOTA_FILE"
    
    # Acquire lock
    if ! core_acquire_lock; then
        log_error "Failed to acquire lock for reading quota"
        return 1
    fi
    
    # Read quota file
    usage=$(security_read_file "$QUOTA_FILE") || {
        log_error "Failed to read quota file: $QUOTA_FILE"
        core_release_lock
        return 1
    }
    
    # Release lock
    core_release_lock
    
    # Validate usage value
    if ! [[ "$usage" =~ ^[0-9]+$ ]]; then
        log_error "Invalid quota value in file: $usage"
        return 1
    fi
    
    echo "$usage"
    return 0
}

# Set current quota usage
core_set_quota() {
    local usage="$1"
    
    if [ -z "$usage" ]; then
        log_error "No quota value specified"
        return 1
    fi
    
    # Validate usage value
    if ! [[ "$usage" =~ ^[0-9]+$ ]]; then
        log_error "Invalid quota value: $usage"
        return 1
    fi
    
    log_debug "Setting quota usage to: $usage"
    
    # Acquire lock
    if ! core_acquire_lock; then
        log_error "Failed to acquire lock for setting quota"
        return 1
    fi
    
    # Write quota file
    if ! security_create_file "$QUOTA_FILE" "0640" "root" "root" "$usage"; then
        log_error "Failed to write quota file: $QUOTA_FILE"
        core_release_lock
        return 1
    fi
    
    # Release lock
    core_release_lock
    
    log_info "Quota usage set to: $usage minutes"
    return 0
}

# Reset quota to zero
core_reset_quota() {
    log_info "Resetting quota to zero"
    
    # Set quota to 0
    if ! core_set_quota 0; then
        log_error "Failed to reset quota"
        return 1
    fi
    
    log_info "Quota reset successfully"
    return 0
}

# Increment quota by specified amount
core_increment_quota() {
    local increment="${1:-1}"  # Default increment: 1 minute
    local current_usage
    local new_usage
    
    # Validate increment value
    if ! [[ "$increment" =~ ^[0-9]+$ ]]; then
        log_error "Invalid increment value: $increment"
        return 1
    fi
    
    log_debug "Incrementing quota by: $increment minutes"
    
    # Get current usage
    current_usage=$(core_get_quota) || {
        log_error "Failed to get current quota usage"
        return 1
    }
    
    # Calculate new usage
    new_usage=$((current_usage + increment))
    
    # Set new usage
    if ! core_set_quota "$new_usage"; then
        log_error "Failed to update quota"
        return 1
    fi
    
    log_info "Quota incremented by $increment to $new_usage minutes"
    return 0
}

# Check if quota is exceeded
core_is_quota_exceeded() {
    local current_usage
    local quota_limit
    
    # Get current usage
    current_usage=$(core_get_quota) || {
        log_error "Failed to get current quota usage"
        return 1
    }
    
    # Get quota limit from configuration
    quota_limit=$(config_get "QUOTA") || {
        log_error "Failed to get quota limit from configuration"
        return 1
    }
    
    log_debug "Checking if quota exceeded: $current_usage/$quota_limit"
    
    # Check if usage exceeds limit
    if [ "$current_usage" -ge "$quota_limit" ]; then
        log_info "Quota exceeded: $current_usage/$quota_limit"
        return 0  # true
    else
        log_debug "Quota not exceeded: $current_usage/$quota_limit"
        return 1  # false
    fi
}

# Get remaining quota
core_get_remaining_quota() {
    local current_usage
    local quota_limit
    local remaining
    
    # Get current usage
    current_usage=$(core_get_quota) || {
        log_error "Failed to get current quota usage"
        return 1
    }
    
    # Get quota limit from configuration
    quota_limit=$(config_get "QUOTA") || {
        log_error "Failed to get quota limit from configuration"
        return 1
    }
    
    # Calculate remaining quota
    remaining=$((quota_limit - current_usage))
    if [ "$remaining" -lt 0 ]; then
        remaining=0
    fi
    
    echo "$remaining"
    return 0
}

# Get quota usage percentage
core_get_quota_percentage() {
    local current_usage
    local quota_limit
    local percentage
    
    # Get current usage
    current_usage=$(core_get_quota) || {
        log_error "Failed to get current quota usage"
        return 1
    }
    
    # Get quota limit from configuration
    quota_limit=$(config_get "QUOTA") || {
        log_error "Failed to get quota limit from configuration"
        return 1
    }
    
    # Avoid division by zero
    if [ "$quota_limit" -eq 0 ]; then
        log_error "Quota limit is set to zero"
        return 1
    fi
    
    # Calculate percentage
    percentage=$((current_usage * 100 / quota_limit))
    
    # Cap at 100%
    if [ "$percentage" -gt 100 ]; then
        percentage=100
    fi
    
    echo "$percentage"
    return 0
}

# Show quota status
core_show_status() {
    local current_usage
    local quota_limit
    local remaining
    local percentage
    local user
    
    # Get user from configuration
    user=$(config_get "USER") || {
        log_error "Failed to get user from configuration"
        return 1
    }
    
    # Get current usage
    current_usage=$(core_get_quota) || {
        log_error "Failed to get current quota usage"
        return 1
    }
    
    # Get quota limit from configuration
    quota_limit=$(config_get "QUOTA") || {
        log_error "Failed to get quota limit from configuration"
        return 1
    }
    
    # Calculate remaining quota
    remaining=$((quota_limit - current_usage))
    if [ "$remaining" -lt 0 ]; then
        remaining=0
    fi
    
    # Calculate percentage
    if [ "$quota_limit" -eq 0 ]; then
        percentage=0
    else
        percentage=$((current_usage * 100 / quota_limit))
        if [ "$percentage" -gt 100 ]; then
            percentage=100
        fi
    fi
    
    # Display status
    echo "Internet Quota Status for user: $user"
    echo "--------------------------------------"
    echo "Quota limit:    $quota_limit minutes"
    echo "Current usage:  $current_usage minutes"
    echo "Remaining:      $remaining minutes"
    echo "Usage:          $percentage%"
    
    # Additional status info
    if core_is_quota_exceeded; then
        echo "Status:         EXCEEDED"
    else
        echo "Status:         ACTIVE"
    fi
    
    echo "--------------------------------------"
    
    return 0
}

# Export variables and functions
export QUOTA_DATA_DIR
export QUOTA_FILE
export QUOTA_LOCK_FILE
export -f core_init
export -f core_acquire_lock
export -f core_release_lock
export -f core_get_quota
export -f core_set_quota
export -f core_reset_quota
export -f core_increment_quota
export -f core_is_quota_exceeded
export -f core_get_remaining_quota
export -f core_get_quota_percentage
export -f core_show_status

# Initialize core module
core_init || {
    log_error "Failed to initialize core module"
    exit 1
} 
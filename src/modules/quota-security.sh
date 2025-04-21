#!/bin/bash
# quota-security.sh - Security module for internet quota system
# Provides functions for secure file operations and permission management

# Import logging module
if [ -f "$(dirname "${BASH_SOURCE[0]}")/quota-logging.sh" ]; then
    # shellcheck source=./quota-logging.sh
    . "$(dirname "${BASH_SOURCE[0]}")/quota-logging.sh"
else
    echo "ERROR: Required module quota-logging.sh not found" >&2
    exit 1
fi

# Default values
QUOTA_DATA_DIR=${QUOTA_DATA_DIR:-"/var/lib/internet-quota"}
DEFAULT_DIR_MODE=${DEFAULT_DIR_MODE:-0750}
DEFAULT_FILE_MODE=${DEFAULT_FILE_MODE:-0640}

# Initialize security module
security_init() {
    log_info "Initializing security module"
    
    # Check if running as root or has sudo capabilities
    if ! security_check_root && ! security_check_sudo; then
        log_error "This script must be run as root or with sudo privileges"
        return 1
    fi
    
    log_info "Security module initialized successfully"
    return 0
}

# Create directory with secure permissions
security_create_dir() {
    local dir_path="$1"
    local mode="${2:-$DEFAULT_DIR_MODE}"
    local owner="${3:-root}"
    local group="${4:-root}"
    
    if [ -z "$dir_path" ]; then
        log_error "No directory path specified"
        return 1
    fi
    
    log_debug "Creating directory: $dir_path (mode: $mode, owner: $owner:$group)"
    
    # Create directory if it doesn't exist
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path" 2>/dev/null || {
            log_error "Failed to create directory: $dir_path"
            return 1
        }
    fi
    
    # Set permissions
    chmod "$mode" "$dir_path" 2>/dev/null || {
        log_warning "Failed to set permissions on directory: $dir_path"
    }
    
    # Set ownership
    chown "$owner:$group" "$dir_path" 2>/dev/null || {
        log_warning "Failed to set ownership on directory: $dir_path"
    }
    
    log_debug "Directory created successfully: $dir_path"
    return 0
}

# Create file with secure permissions
security_create_file() {
    local file_path="$1"
    local mode="${2:-$DEFAULT_FILE_MODE}"
    local owner="${3:-root}"
    local group="${4:-root}"
    local content="$5"
    
    if [ -z "$file_path" ]; then
        log_error "No file path specified"
        return 1
    fi
    
    log_debug "Creating file: $file_path (mode: $mode, owner: $owner:$group)"
    
    # Create parent directory if it doesn't exist
    local dir_path
    dir_path=$(dirname "$file_path")
    if [ ! -d "$dir_path" ]; then
        security_create_dir "$dir_path" || {
            log_error "Failed to create parent directory for file: $file_path"
            return 1
        }
    fi
    
    # Create/truncate file
    if [ -n "$content" ]; then
        echo "$content" > "$file_path" 2>/dev/null || {
            log_error "Failed to write content to file: $file_path"
            return 1
        }
    else
        touch "$file_path" 2>/dev/null || {
            log_error "Failed to create file: $file_path"
            return 1
        }
    fi
    
    # Set permissions
    chmod "$mode" "$file_path" 2>/dev/null || {
        log_warning "Failed to set permissions on file: $file_path"
    }
    
    # Set ownership
    chown "$owner:$group" "$file_path" 2>/dev/null || {
        log_warning "Failed to set ownership on file: $file_path"
    }
    
    log_debug "File created successfully: $file_path"
    return 0
}

# Read file securely
security_read_file() {
    local file_path="$1"
    
    if [ -z "$file_path" ]; then
        log_error "No file path specified"
        return 1
    fi
    
    if [ ! -f "$file_path" ]; then
        log_error "File does not exist: $file_path"
        return 1
    fi
    
    if [ ! -r "$file_path" ]; then
        log_error "No read permission for file: $file_path"
        return 1
    }
    
    local content
    content=$(cat "$file_path" 2>/dev/null) || {
        log_error "Failed to read file: $file_path"
        return 1
    }
    
    echo "$content"
    return 0
}

# Write to file securely
security_write_file() {
    local file_path="$1"
    local content="$2"
    local append="${3:-false}"
    
    if [ -z "$file_path" ]; then
        log_error "No file path specified"
        return 1
    fi
    
    # Create parent directory if it doesn't exist
    local dir_path
    dir_path=$(dirname "$file_path")
    if [ ! -d "$dir_path" ]; then
        security_create_dir "$dir_path" || {
            log_error "Failed to create parent directory for file: $file_path"
            return 1
        }
    fi
    
    # Check if file exists and is writable
    if [ -f "$file_path" ] && [ ! -w "$file_path" ]; then
        log_error "No write permission for file: $file_path"
        return 1
    fi
    
    # Write content to file
    if [ "$append" = "true" ]; then
        echo "$content" >> "$file_path" 2>/dev/null || {
            log_error "Failed to append content to file: $file_path"
            return 1
        }
        log_debug "Content appended to file: $file_path"
    else
        echo "$content" > "$file_path" 2>/dev/null || {
            log_error "Failed to write content to file: $file_path"
            return 1
        }
        log_debug "Content written to file: $file_path"
    fi
    
    return 0
}

# Verify file integrity
security_verify_file() {
    local file_path="$1"
    local expected_owner="${2:-root}"
    local expected_group="${3:-root}"
    local expected_mode="${4:-$DEFAULT_FILE_MODE}"
    
    if [ -z "$file_path" ]; then
        log_error "No file path specified"
        return 1
    fi
    
    if [ ! -f "$file_path" ]; then
        log_error "File does not exist: $file_path"
        return 1
    fi
    
    # Check owner
    local file_owner
    file_owner=$(stat -c "%U" "$file_path" 2>/dev/null)
    if [ "$file_owner" != "$expected_owner" ]; then
        log_warning "Incorrect owner for file: $file_path (expected: $expected_owner, actual: $file_owner)"
        return 1
    fi
    
    # Check group
    local file_group
    file_group=$(stat -c "%G" "$file_path" 2>/dev/null)
    if [ "$file_group" != "$expected_group" ]; then
        log_warning "Incorrect group for file: $file_path (expected: $expected_group, actual: $file_group)"
        return 1
    fi
    
    # Check permissions (mode)
    local file_mode
    file_mode=$(stat -c "%a" "$file_path" 2>/dev/null)
    if [ "$file_mode" != "$expected_mode" ]; then
        log_warning "Incorrect permissions for file: $file_path (expected: $expected_mode, actual: $file_mode)"
        return 1
    fi
    
    log_debug "File integrity verified: $file_path"
    return 0
}

# Initialize data directory
security_init_data_dir() {
    local data_dir="${1:-$QUOTA_DATA_DIR}"
    local dir_mode="${2:-$DEFAULT_DIR_MODE}"
    local owner="${3:-root}"
    local group="${4:-root}"
    
    log_info "Initializing data directory: $data_dir"
    
    # Create data directory with secure permissions
    security_create_dir "$data_dir" "$dir_mode" "$owner" "$group" || {
        log_error "Failed to initialize data directory: $data_dir"
        return 1
    }
    
    log_info "Data directory initialized successfully: $data_dir"
    return 0
}

# Clean up security-related resources
security_cleanup() {
    log_info "Cleaning up security resources"
    # Any cleanup operations can be added here
    return 0
}

# Check if running as root
security_check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Check if has sudo capabilities
security_check_sudo() {
    if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Export variables and functions
export QUOTA_DATA_DIR
export DEFAULT_DIR_MODE
export DEFAULT_FILE_MODE
export -f security_init
export -f security_create_dir
export -f security_create_file
export -f security_read_file
export -f security_write_file
export -f security_verify_file
export -f security_init_data_dir
export -f security_cleanup
export -f security_check_root
export -f security_check_sudo

# Initialize security module
security_init || {
    log_error "Failed to initialize security module"
    exit 1
} 
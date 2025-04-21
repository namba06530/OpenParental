#!/bin/bash

# Log levels
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
    ["SECURITY"]=4
)

# Default configuration
LOG_LEVEL=${LOG_LEVEL:-"INFO"}
LOG_DIR=${LOG_DIR:-"/var/log/openparental/quota"}
LOG_MAX_SIZE=${LOG_MAX_SIZE:-10485760}  # 10MB default
LOG_MAX_FILES=${LOG_MAX_FILES:-7}       # 7 days default
QUOTA_LOG="$LOG_DIR/quota.log"
DEBUG_LOG="$LOG_DIR/debug.log"
SECURITY_LOG="$LOG_DIR/security.log"
ERROR_LOG="$LOG_DIR/errors.log"

# Console colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Logging initialization
init_logging() {
    local module="$1"
    
    # Create directories
    mkdir -p "$LOG_DIR"
    
    # Create log files if they don't exist
    touch "$QUOTA_LOG" "$DEBUG_LOG" "$SECURITY_LOG" "$ERROR_LOG"
    
    log_info "$module" "system" "Logging system initialized"
}

# Setup log rotation
setup_log_rotation() {
    local service_name="$1"
    local log_dir="$2"
    local max_size="$3"
    local max_files="$4"
    
    # Create logrotate configuration
    local logrotate_conf="/etc/logrotate.d/$service_name"
    
    # Only try to create logrotate config if we have permission
    if [ -w "/etc/logrotate.d" ]; then
        cat > "$logrotate_conf" << EOF
$log_dir/*.log {
    daily
    missingok
    rotate $max_files
    compress
    delaycompress
    notifempty
    create 644 root root
    size $max_size
    postrotate
        /usr/bin/killall -HUP rsyslogd >/dev/null 2>&1 || true
    endscript
}
EOF
        chmod 644 "$logrotate_conf"
    else
        log_warn "$service_name" "system" "No permission to create logrotate configuration at $logrotate_conf"
    fi
}

# Log cleanup and rotation
cleanup_logs() {
    local module="$1"
    local log_file="$2"
    
    # Check file size
    local size=$(wc -c < "$log_file" 2>/dev/null || echo 0)
    if [ "$size" -gt "$LOG_MAX_SIZE" ]; then
        rotate_log "$module" "$log_file"
    fi
}

# Manual log rotation
rotate_log() {
    local module="$1"
    local log_file="$2"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local archive_file="${log_file}.${timestamp}"
    
    # Copy and compress current file
    cp "$log_file" "$archive_file"
    gzip "$archive_file"
    
    # Reset log file
    echo "" > "$log_file"
    
    log_info "$module" "system" "Log file rotated: $archive_file.gz"
}

# Log status check
check_log_status() {
    local module="$1"
    local log_file="$2"
    
    if [ ! -f "$log_file" ]; then
        log_error "$module" "system" "Log file $log_file does not exist"
        return 1
    fi
    
    local size=$(wc -c < "$log_file" 2>/dev/null || echo 0)
    local files_count=$(find "$LOG_DIR" -name "*.log.*" | wc -l)
    
    log_debug "$module" "system" "Log status: size=${size}B, archived_files=$files_count"
    return 0
}

# Generic logging function
_log() {
    local level="$1"
    local module="$2"
    local user="$3"
    local message="$4"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Message format
    local log_message="[$timestamp][$level][$module][$user] $message"
    
    # Write to appropriate files
    case "$level" in
        "DEBUG")
            echo "$log_message" >> "$DEBUG_LOG"
            cleanup_logs "$module" "$DEBUG_LOG"
            ;;
        "SECURITY")
            echo "$log_message" >> "$SECURITY_LOG"
            cleanup_logs "$module" "$SECURITY_LOG"
            ;;
        *)
            # For other levels, write to main file if level is sufficient
            if [ "${LOG_LEVELS[$level]}" -ge "${LOG_LEVELS[$LOG_LEVEL]}" ]; then
                echo "$log_message" >> "$QUOTA_LOG"
                cleanup_logs "$module" "$QUOTA_LOG"
            fi
            ;;
    esac
}

# Logging functions by level
log_debug() {
    if [ "${LOG_LEVELS[DEBUG]}" -ge "${LOG_LEVELS[$LOG_LEVEL]}" ]; then
        _log "DEBUG" "$1" "$2" "$3"
    fi
}

log_info() {
    if [ "${LOG_LEVELS[INFO]}" -ge "${LOG_LEVELS[$LOG_LEVEL]}" ]; then
        _log "INFO" "$1" "$2" "$3"
    fi
}

log_warn() {
    if [ "${LOG_LEVELS[WARN]}" -ge "${LOG_LEVELS[$LOG_LEVEL]}" ]; then
        _log "WARN" "$1" "$2" "$3"
    fi
}

log_error() {
    if [ "${LOG_LEVELS[ERROR]}" -ge "${LOG_LEVELS[$LOG_LEVEL]}" ]; then
        _log "ERROR" "$1" "$2" "$3"
    fi
}

log_security() {
    _log "SECURITY" "$1" "$2" "$3"
}

# Log level management
get_log_level() {
    echo "$LOG_LEVEL"
}

set_log_level() {
    local new_level=$1
    if [[ -n "${LOG_LEVELS[$new_level]}" ]]; then
        LOG_LEVEL=$new_level
        return 0
    else
        echo "Invalid log level: $new_level" >&2
        return 1
    fi
}

# Export functions
export -f init_logging check_log_status rotate_log cleanup_logs setup_log_rotation
export -f log_debug log_info log_warn log_error log_security
export -f get_log_level set_log_level 
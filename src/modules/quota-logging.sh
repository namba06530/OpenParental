#!/bin/bash
# quota-logging.sh - Logging module for internet quota system
# Provides standardized logging functions for all quota modules

# Default log locations
DEFAULT_LOG_DIR=${DEFAULT_LOG_DIR:-"/var/log/internet-quota"}
DEFAULT_LOG_FILE=${DEFAULT_LOG_FILE:-"$DEFAULT_LOG_DIR/quota.log"}
DEFAULT_DEBUG_LOG_FILE=${DEFAULT_DEBUG_LOG_FILE:-"$DEFAULT_LOG_DIR/debug.log"}

# Log levels
LOG_LEVEL_ERROR=0
LOG_LEVEL_WARNING=1
LOG_LEVEL_INFO=2
LOG_LEVEL_DEBUG=3

# Current log level (default: INFO)
CURRENT_LOG_LEVEL=${CURRENT_LOG_LEVEL:-$LOG_LEVEL_INFO}

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize logging
log_init() {
    # Create log directory if it doesn't exist
    if [ ! -d "$DEFAULT_LOG_DIR" ]; then
        mkdir -p "$DEFAULT_LOG_DIR" 2>/dev/null || {
            echo "ERROR: Failed to create log directory: $DEFAULT_LOG_DIR" >&2
            return 1
        }
        chmod 750 "$DEFAULT_LOG_DIR" 2>/dev/null
    fi
    
    # Create log files if they don't exist
    if [ ! -f "$DEFAULT_LOG_FILE" ]; then
        touch "$DEFAULT_LOG_FILE" 2>/dev/null || {
            echo "ERROR: Failed to create log file: $DEFAULT_LOG_FILE" >&2
            return 1
        }
        chmod 640 "$DEFAULT_LOG_FILE" 2>/dev/null
    fi
    
    if [ ! -f "$DEFAULT_DEBUG_LOG_FILE" ]; then
        touch "$DEFAULT_DEBUG_LOG_FILE" 2>/dev/null || {
            echo "ERROR: Failed to create debug log file: $DEFAULT_DEBUG_LOG_FILE" >&2
            return 1
        }
        chmod 640 "$DEFAULT_DEBUG_LOG_FILE" 2>/dev/null
    fi
    
    # Log initialization
    log_info "Logging system initialized"
    return 0
}

# Set log level
log_set_level() {
    local level="$1"
    
    case "$level" in
        "ERROR"|"error"|"0")
            CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR
            ;;
        "WARNING"|"warning"|"1")
            CURRENT_LOG_LEVEL=$LOG_LEVEL_WARNING
            ;;
        "INFO"|"info"|"2")
            CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO
            ;;
        "DEBUG"|"debug"|"3")
            CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
            ;;
        *)
            echo "ERROR: Invalid log level: $level" >&2
            return 1
            ;;
    esac
    
    log_info "Log level set to: $level"
    return 0
}

# Get current log level as string
log_get_level() {
    case "$CURRENT_LOG_LEVEL" in
        $LOG_LEVEL_ERROR)
            echo "ERROR"
            ;;
        $LOG_LEVEL_WARNING)
            echo "WARNING"
            ;;
        $LOG_LEVEL_INFO)
            echo "INFO"
            ;;
        $LOG_LEVEL_DEBUG)
            echo "DEBUG"
            ;;
        *)
            echo "UNKNOWN"
            ;;
    esac
}

# Internal logging function
_log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_message="[$timestamp] [$level] $message"
    
    # Log to file
    echo "$log_message" >> "$DEFAULT_LOG_FILE"
    
    # Log debug messages to debug log file
    if [ "$level" = "DEBUG" ]; then
        echo "$log_message" >> "$DEFAULT_DEBUG_LOG_FILE"
    fi
    
    # Log errors to stderr, others to stdout
    if [ "$level" = "ERROR" ]; then
        echo -e "${RED}$log_message${NC}" >&2
    elif [ "$level" = "WARNING" ]; then
        echo -e "${YELLOW}$log_message${NC}"
    elif [ "$level" = "INFO" ]; then
        echo -e "${GREEN}$log_message${NC}"
    elif [ "$level" = "DEBUG" ]; then
        echo -e "${BLUE}$log_message${NC}"
    else
        echo "$log_message"
    fi
    
    return 0
}

# Log error message
log_error() {
    local message="$1"
    
    if [ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_ERROR ]; then
        _log "ERROR" "$message"
    fi
    
    return 0
}

# Log warning message
log_warning() {
    local message="$1"
    
    if [ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_WARNING ]; then
        _log "WARNING" "$message"
    fi
    
    return 0
}

# Log info message
log_info() {
    local message="$1"
    
    if [ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_INFO ]; then
        _log "INFO" "$message"
    fi
    
    return 0
}

# Log debug message
log_debug() {
    local message="$1"
    
    if [ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_DEBUG ]; then
        _log "DEBUG" "$message"
    fi
    
    return 0
}

# Log a separator line
log_separator() {
    local level="${1:-INFO}"
    local length="${2:-50}"
    local char="${3:--}"
    local line
    
    # Create a line of specified length using the specified character
    line=$(printf "%${length}s" | tr " " "$char")
    
    case "$level" in
        "ERROR"|"error")
            log_error "$line"
            ;;
        "WARNING"|"warning")
            log_warning "$line"
            ;;
        "INFO"|"info")
            log_info "$line"
            ;;
        "DEBUG"|"debug")
            log_debug "$line"
            ;;
        *)
            log_info "$line"
            ;;
    esac
    
    return 0
}

# Clean old log files
log_cleanup() {
    local max_days="${1:-30}"
    local log_dir="${2:-$DEFAULT_LOG_DIR}"
    
    if [ ! -d "$log_dir" ]; then
        log_error "Log directory does not exist: $log_dir"
        return 1
    fi
    
    log_info "Cleaning log files older than $max_days days in $log_dir"
    
    # Find and delete old log files
    find "$log_dir" -name "*.log" -type f -mtime +"$max_days" -delete 2>/dev/null
    if [ $? -ne 0 ]; then
        log_warning "Failed to clean old log files"
        return 1
    fi
    
    log_info "Log cleanup complete"
    return 0
}

# Rotate log files
log_rotate() {
    local max_size="${1:-10485760}" # Default: 10MB
    local log_file="${2:-$DEFAULT_LOG_FILE}"
    local debug_log_file="${3:-$DEFAULT_DEBUG_LOG_FILE}"
    local backup_suffix
    
    # Get current timestamp for backup files
    backup_suffix=$(date '+%Y%m%d_%H%M%S')
    
    # Check and rotate main log file
    if [ -f "$log_file" ] && [ "$(stat -c%s "$log_file" 2>/dev/null || echo 0)" -gt "$max_size" ]; then
        log_info "Rotating main log file: $log_file"
        
        # Create backup of current log file
        cp "$log_file" "${log_file}.${backup_suffix}" 2>/dev/null || {
            log_warning "Failed to create backup of log file"
        }
        
        # Truncate current log file
        cat /dev/null > "$log_file" 2>/dev/null || {
            log_error "Failed to truncate log file: $log_file"
            return 1
        }
        
        log_info "Main log file rotated successfully"
    fi
    
    # Check and rotate debug log file
    if [ -f "$debug_log_file" ] && [ "$(stat -c%s "$debug_log_file" 2>/dev/null || echo 0)" -gt "$max_size" ]; then
        log_info "Rotating debug log file: $debug_log_file"
        
        # Create backup of current debug log file
        cp "$debug_log_file" "${debug_log_file}.${backup_suffix}" 2>/dev/null || {
            log_warning "Failed to create backup of debug log file"
        }
        
        # Truncate current debug log file
        cat /dev/null > "$debug_log_file" 2>/dev/null || {
            log_error "Failed to truncate debug log file: $debug_log_file"
            return 1
        }
        
        log_info "Debug log file rotated successfully"
    fi
    
    return 0
}

# Export variables and functions
export DEFAULT_LOG_DIR
export DEFAULT_LOG_FILE
export DEFAULT_DEBUG_LOG_FILE
export CURRENT_LOG_LEVEL
export LOG_LEVEL_ERROR
export LOG_LEVEL_WARNING
export LOG_LEVEL_INFO
export LOG_LEVEL_DEBUG
export -f log_init
export -f log_set_level
export -f log_get_level
export -f log_error
export -f log_warning
export -f log_info
export -f log_debug
export -f log_separator
export -f log_cleanup
export -f log_rotate

# Initialize logging
log_init || {
    echo "ERROR: Failed to initialize logging system" >&2
    exit 1
} 
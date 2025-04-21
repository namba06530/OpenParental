#!/bin/bash
# quota-config.sh - Configuration module for internet quota system
# Provides functions for managing configuration parameters

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

# Default configuration values
CONFIG_DIR=${CONFIG_DIR:-"/etc/internet-quota"}
CONFIG_FILE="${CONFIG_DIR}/config.conf"

# Default quota settings
DEFAULT_QUOTA=${DEFAULT_QUOTA:-60} # Default quota in minutes
DEFAULT_USER=${DEFAULT_USER:-""} # Default user to track
DEFAULT_RESET_TIME=${DEFAULT_RESET_TIME:-"00:00"} # Default reset time (midnight)
DEFAULT_WHITELIST_ENABLED=${DEFAULT_WHITELIST_ENABLED:-"false"} # Default whitelist status
DEFAULT_WHITELIST_SITES=${DEFAULT_WHITELIST_SITES:-""} # Default whitelist sites

# Initialize configuration module
config_init() {
    log_info "Initializing configuration module"
    
    # Create configuration directory if it doesn't exist
    if ! security_create_dir "$CONFIG_DIR" "0750" "root" "root"; then
        log_error "Failed to create configuration directory: $CONFIG_DIR"
        return 1
    fi
    
    # Create default configuration file if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        log_info "Creating default configuration file: $CONFIG_FILE"
        
        local default_config="# Internet Quota Configuration
# Generated on $(date)

# User to track internet usage
USER=${DEFAULT_USER}

# Daily quota in minutes
QUOTA=${DEFAULT_QUOTA}

# Time to reset quota (24h format, HH:MM)
RESET_TIME=${DEFAULT_RESET_TIME}

# Whitelist configuration
WHITELIST_ENABLED=${DEFAULT_WHITELIST_ENABLED}
WHITELIST_SITES=\"${DEFAULT_WHITELIST_SITES}\"
"
        if ! security_create_file "$CONFIG_FILE" "0640" "root" "root" "$default_config"; then
            log_error "Failed to create default configuration file: $CONFIG_FILE"
            return 1
        fi
    fi
    
    log_info "Configuration module initialized successfully"
    return 0
}

# Load configuration from file
config_load() {
    log_info "Loading configuration from $CONFIG_FILE"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    if [ ! -r "$CONFIG_FILE" ]; then
        log_error "Configuration file not readable: $CONFIG_FILE"
        return 1
    }
    
    # Source the configuration file
    # shellcheck source=/etc/internet-quota/config.conf
    . "$CONFIG_FILE" || {
        log_error "Failed to load configuration from $CONFIG_FILE"
        return 1
    }
    
    # Set variables with default values if not defined in config
    USER=${USER:-$DEFAULT_USER}
    QUOTA=${QUOTA:-$DEFAULT_QUOTA}
    RESET_TIME=${RESET_TIME:-$DEFAULT_RESET_TIME}
    WHITELIST_ENABLED=${WHITELIST_ENABLED:-$DEFAULT_WHITELIST_ENABLED}
    WHITELIST_SITES=${WHITELIST_SITES:-$DEFAULT_WHITELIST_SITES}
    
    log_info "Configuration loaded successfully"
    return 0
}

# Get configuration value
config_get() {
    local key="$1"
    local default_value="$2"
    
    if [ -z "$key" ]; then
        log_error "No configuration key specified"
        return 1
    fi
    
    # Load configuration if not already loaded
    if [ -z "$USER" ] && [ -z "$QUOTA" ]; then
        config_load || return 1
    fi
    
    # Get the value
    local value
    case "$key" in
        "USER") 
            value="$USER"
            ;;
        "QUOTA") 
            value="$QUOTA"
            ;;
        "RESET_TIME") 
            value="$RESET_TIME"
            ;;
        "WHITELIST_ENABLED") 
            value="$WHITELIST_ENABLED"
            ;;
        "WHITELIST_SITES") 
            value="$WHITELIST_SITES"
            ;;
        *) 
            log_warning "Unknown configuration key: $key"
            value="$default_value"
            ;;
    esac
    
    # Return default value if value is empty
    if [ -z "$value" ]; then
        value="$default_value"
    fi
    
    echo "$value"
    return 0
}

# Set configuration value
config_set() {
    local key="$1"
    local value="$2"
    
    if [ -z "$key" ]; then
        log_error "No configuration key specified"
        return 1
    fi
    
    if [ -z "$value" ]; then
        log_error "No value specified for key: $key"
        return 1
    fi
    
    log_info "Setting configuration: $key=$value"
    
    # Load configuration if not already loaded
    if [ -z "$USER" ] && [ -z "$QUOTA" ]; then
        config_load || return 1
    fi
    
    # Update the value in memory
    case "$key" in
        "USER") 
            USER="$value"
            ;;
        "QUOTA") 
            QUOTA="$value"
            ;;
        "RESET_TIME") 
            RESET_TIME="$value"
            ;;
        "WHITELIST_ENABLED") 
            WHITELIST_ENABLED="$value"
            ;;
        "WHITELIST_SITES") 
            WHITELIST_SITES="$value"
            ;;
        *) 
            log_error "Unknown configuration key: $key"
            return 1
            ;;
    esac
    
    # Update the configuration file
    config_save || return 1
    
    log_info "Configuration updated: $key=$value"
    return 0
}

# Save configuration to file
config_save() {
    log_info "Saving configuration to $CONFIG_FILE"
    
    # Create configuration content
    local config_content="# Internet Quota Configuration
# Updated on $(date)

# User to track internet usage
USER=\"${USER}\"

# Daily quota in minutes
QUOTA=${QUOTA}

# Time to reset quota (24h format, HH:MM)
RESET_TIME=\"${RESET_TIME}\"

# Whitelist configuration
WHITELIST_ENABLED=${WHITELIST_ENABLED}
WHITELIST_SITES=\"${WHITELIST_SITES}\"
"
    
    # Save to file
    if ! security_create_file "$CONFIG_FILE" "0640" "root" "root" "$config_content"; then
        log_error "Failed to save configuration to $CONFIG_FILE"
        return 1
    fi
    
    log_info "Configuration saved successfully"
    return 0
}

# Validate configuration
config_validate() {
    log_info "Validating configuration"
    
    # Load configuration if not already loaded
    if [ -z "$USER" ] && [ -z "$QUOTA" ]; then
        config_load || return 1
    fi
    
    # Validate USER
    if [ -z "$USER" ]; then
        log_error "USER not configured"
        return 1
    fi
    
    # Validate user exists
    if ! id "$USER" >/dev/null 2>&1; then
        log_error "Configured user does not exist: $USER"
        return 1
    fi
    
    # Validate QUOTA
    if ! [[ "$QUOTA" =~ ^[0-9]+$ ]]; then
        log_error "QUOTA must be a positive integer: $QUOTA"
        return 1
    fi
    
    # Validate RESET_TIME
    if ! [[ "$RESET_TIME" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
        log_error "RESET_TIME must be in 24h format (HH:MM): $RESET_TIME"
        return 1
    fi
    
    # Validate WHITELIST_ENABLED
    if [ "$WHITELIST_ENABLED" != "true" ] && [ "$WHITELIST_ENABLED" != "false" ]; then
        log_error "WHITELIST_ENABLED must be 'true' or 'false': $WHITELIST_ENABLED"
        return 1
    fi
    
    # If whitelist is enabled, validate it has content
    if [ "$WHITELIST_ENABLED" = "true" ] && [ -z "$WHITELIST_SITES" ]; then
        log_warning "WHITELIST_ENABLED is true but WHITELIST_SITES is empty"
    fi
    
    log_info "Configuration validated successfully"
    return 0
}

# Reset configuration to defaults
config_reset() {
    log_info "Resetting configuration to defaults"
    
    # Set variables to default values
    USER="$DEFAULT_USER"
    QUOTA="$DEFAULT_QUOTA"
    RESET_TIME="$DEFAULT_RESET_TIME"
    WHITELIST_ENABLED="$DEFAULT_WHITELIST_ENABLED"
    WHITELIST_SITES="$DEFAULT_WHITELIST_SITES"
    
    # Save to file
    config_save || return 1
    
    log_info "Configuration reset to defaults"
    return 0
}

# Export variables and functions
export CONFIG_DIR
export CONFIG_FILE
export DEFAULT_QUOTA
export DEFAULT_USER
export DEFAULT_RESET_TIME
export DEFAULT_WHITELIST_ENABLED
export DEFAULT_WHITELIST_SITES
export -f config_init
export -f config_load
export -f config_get
export -f config_set
export -f config_save
export -f config_validate
export -f config_reset

# Initialize configuration module
config_init || {
    log_error "Failed to initialize configuration module"
    exit 1
} 
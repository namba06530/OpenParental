#!/bin/bash
# quota-network.sh - Network control functions for internet quota
# This module handles network access control for quota enforcement

# Load common libraries if not already loaded
if ! command -v log_info &>/dev/null; then
    # Check if we can find the logging library
    if [ -f "$(dirname "$0")/../lib/logging.sh" ]; then
        source "$(dirname "$0")/../lib/logging.sh"
    elif [ -f "/usr/local/bin/lib/logging.sh" ]; then
        source "/usr/local/bin/lib/logging.sh"
    fi
fi

if ! command -v handle_error &>/dev/null; then
    # Check if we can find the error handling library
    if [ -f "$(dirname "$0")/../lib/error-handling.sh" ]; then
        source "$(dirname "$0")/../lib/error-handling.sh"
    elif [ -f "/usr/local/bin/lib/error-handling.sh" ]; then
        source "/usr/local/bin/lib/error-handling.sh"
    fi
fi

# Simple fallback logging if libraries are not available
if ! command -v log_info &>/dev/null; then
    log_info() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $3" | tee -a /tmp/quota-debug.log
    }
    
    log_error() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $3" >&2 | tee -a /tmp/quota-debug.log
    }
}

# Constants
QUOTA_CHAIN_NAME="QUOTA_TIME"
WHITELIST_CHAIN_NAME="WHITELIST"

#################################################
# Check if the system has the required network tools
# Returns:
#   0 if all required tools are available, non-zero otherwise
#################################################
network_check_dependencies() {
    local missing=()
    
    # Check for iptables
    if ! command -v iptables &>/dev/null; then
        missing+=("iptables")
    fi
    
    # Check for ip command
    if ! command -v ip &>/dev/null; then
        missing+=("iproute2")
    fi
    
    # Report missing dependencies
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "quota-network" "system" "Missing dependencies: ${missing[*]}"
        return 1
    fi
    
    log_info "quota-network" "system" "All network dependencies are available"
    return 0
}

#################################################
# Setup iptables chains required for quota control
# Returns:
#   0 if successful, non-zero otherwise
#################################################
network_setup_chains() {
    log_info "quota-network" "system" "Setting up iptables chains"
    
    # Ensure we have iptables
    if ! command -v iptables &>/dev/null; then
        log_error "quota-network" "system" "iptables not found"
        return 1
    fi
    
    # Create the QUOTA_TIME chain if it doesn't exist
    iptables -L "$QUOTA_CHAIN_NAME" -n &>/dev/null
    if [ $? -ne 0 ]; then
        log_info "quota-network" "system" "Creating $QUOTA_CHAIN_NAME chain"
        iptables -N "$QUOTA_CHAIN_NAME"
    else
        log_info "quota-network" "system" "$QUOTA_CHAIN_NAME chain already exists"
    fi
    
    # Create the WHITELIST chain if it doesn't exist
    iptables -L "$WHITELIST_CHAIN_NAME" -n &>/dev/null
    if [ $? -ne 0 ]; then
        log_info "quota-network" "system" "Creating $WHITELIST_CHAIN_NAME chain"
        iptables -N "$WHITELIST_CHAIN_NAME"
    else
        log_info "quota-network" "system" "$WHITELIST_CHAIN_NAME chain already exists"
    fi
    
    # Make sure the chain is empty and has the default policy
    iptables -F "$QUOTA_CHAIN_NAME"
    iptables -F "$WHITELIST_CHAIN_NAME"
    
    # Add default rules to the WHITELIST chain
    # By default, return to the calling chain (no action)
    iptables -A "$WHITELIST_CHAIN_NAME" -j RETURN
    
    log_info "quota-network" "system" "iptables chains setup completed"
    return 0
}

#################################################
# Add a user-specific rule to control their internet access
# Arguments:
#   $1 - Username
#   $2 - UID of the user
# Returns:
#   0 if successful, non-zero otherwise
#################################################
network_add_user_rule() {
    local username="$1"
    local uid="$2"
    
    log_info "quota-network" "system" "Adding network rules for user $username"
    
    # Get UID if not provided
    if [ -z "$uid" ]; then
        uid=$(id -u "$username" 2>/dev/null)
        if [ $? -ne 0 ]; then
            log_error "quota-network" "system" "User $username not found"
            return 1
        fi
    fi
    
    # Ensure chains exist
    network_setup_chains
    
    # Add rule to jump to QUOTA_TIME chain for this user
    # Check if the rule already exists
    iptables -C OUTPUT -m owner --uid-owner "$uid" -j "$QUOTA_CHAIN_NAME" &>/dev/null
    if [ $? -ne 0 ]; then
        log_info "quota-network" "system" "Adding rule for UID $uid to OUTPUT chain"
        iptables -A OUTPUT -m owner --uid-owner "$uid" -j "$QUOTA_CHAIN_NAME"
    else
        log_info "quota-network" "system" "Rule for UID $uid already exists in OUTPUT chain"
    fi
    
    # Add rule to check WHITELIST first in QUOTA_TIME chain
    iptables -C "$QUOTA_CHAIN_NAME" -j "$WHITELIST_CHAIN_NAME" &>/dev/null
    if [ $? -ne 0 ]; then
        log_info "quota-network" "system" "Adding whitelist rule to $QUOTA_CHAIN_NAME chain"
        iptables -I "$QUOTA_CHAIN_NAME" 1 -j "$WHITELIST_CHAIN_NAME"
    else
        log_info "quota-network" "system" "Whitelist rule already exists in $QUOTA_CHAIN_NAME chain"
    fi
    
    log_info "quota-network" "system" "User rules added successfully"
    return 0
}

#################################################
# Remove user-specific rules for internet access
# Arguments:
#   $1 - Username
#   $2 - UID of the user
# Returns:
#   0 if successful, non-zero otherwise
#################################################
network_remove_user_rule() {
    local username="$1"
    local uid="$2"
    
    log_info "quota-network" "system" "Removing network rules for user $username"
    
    # Get UID if not provided
    if [ -z "$uid" ]; then
        uid=$(id -u "$username" 2>/dev/null)
        if [ $? -ne 0 ]; then
            log_error "quota-network" "system" "User $username not found"
            return 1
        fi
    fi
    
    # Remove the rule from OUTPUT chain
    iptables -D OUTPUT -m owner --uid-owner "$uid" -j "$QUOTA_CHAIN_NAME" &>/dev/null
    
    log_info "quota-network" "system" "User rules removed successfully"
    return 0
}

#################################################
# Enable or disable internet access for a user
# Arguments:
#   $1 - Username
#   $2 - UID of the user
#   $3 - Action: "block" or "allow"
# Returns:
#   0 if successful, non-zero otherwise
#################################################
network_control_access() {
    local username="$1"
    local uid="$2"
    local action="$3"
    
    log_info "quota-network" "system" "Controlling internet access for user $username: $action"
    
    # Get UID if not provided
    if [ -z "$uid" ]; then
        uid=$(id -u "$username" 2>/dev/null)
        if [ $? -ne 0 ]; then
            log_error "quota-network" "system" "User $username not found"
            return 1
        fi
    fi
    
    # Ensure user rules exist
    network_add_user_rule "$username" "$uid"
    
    # Implement the action
    case "$action" in
        block)
            # Check if the rule already exists
            iptables -C "$QUOTA_CHAIN_NAME" -m owner --uid-owner "$uid" -j DROP &>/dev/null
            if [ $? -ne 0 ]; then
                # Rule doesn't exist, add it
                iptables -A "$QUOTA_CHAIN_NAME" -m owner --uid-owner "$uid" -j DROP
                log_info "quota-network" "$username" "Internet access blocked"
            else
                log_info "quota-network" "$username" "Internet access already blocked"
            fi
            ;;
        allow)
            # Remove any blocking rules
            iptables -D "$QUOTA_CHAIN_NAME" -m owner --uid-owner "$uid" -j DROP &>/dev/null
            log_info "quota-network" "$username" "Internet access allowed"
            ;;
        *)
            log_error "quota-network" "system" "Invalid action: $action"
            return 1
            ;;
    esac
    
    return 0
}

#################################################
# Add a domain to the whitelist (always allowed)
# Arguments:
#   $1 - Domain to whitelist
# Returns:
#   0 if successful, non-zero otherwise
#################################################
network_add_whitelist() {
    local domain="$1"
    
    log_info "quota-network" "system" "Adding domain to whitelist: $domain"
    
    # Ensure chains exist
    network_setup_chains
    
    # Resolve domain to IP
    local ips=$(host "$domain" | grep "has address" | awk '{print $4}')
    if [ -z "$ips" ]; then
        log_error "quota-network" "system" "Could not resolve domain: $domain"
        return 1
    fi
    
    # Add rules for each IP
    for ip in $ips; do
        # Check if the rule already exists
        iptables -C "$WHITELIST_CHAIN_NAME" -d "$ip" -j RETURN &>/dev/null
        if [ $? -ne 0 ]; then
            # Rule doesn't exist, add it
            iptables -I "$WHITELIST_CHAIN_NAME" 1 -d "$ip" -j RETURN
            log_info "quota-network" "system" "Added $ip ($domain) to whitelist"
        else
            log_info "quota-network" "system" "$ip ($domain) already in whitelist"
        fi
    done
    
    return 0
}

#################################################
# Clean up all quota-related iptables rules
# Returns:
#   0 if successful, non-zero otherwise
#################################################
network_cleanup() {
    log_info "quota-network" "system" "Cleaning up network rules"
    
    # Remove OUTPUT chain rules
    iptables -S OUTPUT | grep -F "$QUOTA_CHAIN_NAME" | sed 's/^-A/iptables -D/' | bash || true
    
    # Flush and delete chains
    iptables -F "$QUOTA_CHAIN_NAME" 2>/dev/null
    iptables -X "$QUOTA_CHAIN_NAME" 2>/dev/null
    
    iptables -F "$WHITELIST_CHAIN_NAME" 2>/dev/null
    iptables -X "$WHITELIST_CHAIN_NAME" 2>/dev/null
    
    log_info "quota-network" "system" "Network rules cleanup completed"
    return 0
}

# Export functions
export -f network_check_dependencies network_setup_chains
export -f network_add_user_rule network_remove_user_rule 
export -f network_control_access network_add_whitelist network_cleanup 
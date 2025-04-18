#!/bin/bash
set -euo pipefail

# Utility functions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# Load configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "/usr/local/bin/.env.quota" ]; then
    source "/usr/local/bin/.env.quota"
elif [ -f "$SCRIPT_DIR/.env.quota" ]; then
    source "$SCRIPT_DIR/.env.quota"
else
    error ".env.quota file not found in /usr/local/bin or $SCRIPT_DIR"
fi

# Whitelist management
generate_whitelist() {
    iptables -F WHITELIST 2>/dev/null || iptables -N WHITELIST
    for DOMAIN in "${WHITELIST_DOMAINS[@]}"; do
        IP_LIST=$(getent ahosts "$DOMAIN" | awk '{print $1}' | sort | uniq)
        for IP in $IP_LIST; do
            iptables -A WHITELIST -m owner --uid-owner "$CHILD_USERNAME" -d "$IP" -j ACCEPT
        done
    done
    iptables -C OUTPUT -j WHITELIST 2>/dev/null || iptables -I OUTPUT 1 -j WHITELIST
}

# Block Internet if quota exceeded
block_internet() {
    iptables -C QUOTA_TIME -m owner --uid-owner "$CHILD_USERNAME" -j DROP 2>/dev/null || \
        iptables -A QUOTA_TIME -m owner --uid-owner "$CHILD_USERNAME" -j DROP
}

delete_block() {
    iptables -D QUOTA_TIME -m owner --uid-owner "$CHILD_USERNAME" -j DROP 2>/dev/null || true
}

# Graphical notification
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="$3"
    local icon="$4"
    if command -v notify-send >/dev/null 2>&1; then
        sudo -u "$CHILD_USERNAME" \
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u "$CHILD_USERNAME")/bus \
        notify-send "$title" "$message" -u "$urgency" -i "$icon"
    fi
}

# Quota tracking (track mode)
track_quota() {
    local DATE=$(date +%Y-%m-%d)
    local LOG_FILE="$QUOTA_SESSION_DIR/$CHILD_USERNAME.log"
    mkdir -p "$QUOTA_SESSION_DIR"
    [ -f "$LOG_FILE" ] || echo "$DATE 0" > "$LOG_FILE"
    local CURRENT_MINUTES=$(grep "^$DATE" "$LOG_FILE" | cut -d' ' -f2 || echo 0)
    local NEW_MINUTES=$((CURRENT_MINUTES + 1))
    sed -i "/^$DATE/d" "$LOG_FILE"
    echo "$DATE $NEW_MINUTES" >> "$LOG_FILE"
    local REMAINING=$((QUOTA_DAILY_MINUTES - NEW_MINUTES))
    if [ $REMAINING -eq 10 ]; then
        send_notification "Internet Quota" "10 minutes of Internet remaining today!" "normal" "clock"
    elif [ $REMAINING -eq 5 ]; then
        send_notification "Internet Quota" "Only 5 minutes of Internet left!" "critical" "clock"
    elif [ $REMAINING -le 0 ]; then
        send_notification "Internet Quota" "Internet access blocked until midnight" "critical" "dialog-error"
        block_internet
    fi
}

# Reset quota (reset mode)
reset_quota() {
    local DATE=$(date +%Y-%m-%d)
    local LOG_FILE="$QUOTA_SESSION_DIR/$CHILD_USERNAME.log"
    echo "$DATE 0" > "$LOG_FILE"
    delete_block
    generate_whitelist
    send_notification "Internet Quota" "Your Internet quota has been reset" "normal" "clock"
}

# Initialize iptables chains
init_iptables() {
    iptables -N QUOTA_TIME 2>/dev/null || true
    iptables -F QUOTA_TIME
    iptables -N WHITELIST 2>/dev/null || true
    iptables -F WHITELIST
    iptables -C OUTPUT -j WHITELIST 2>/dev/null || iptables -I OUTPUT 1 -j WHITELIST
    iptables -C QUOTA_TIME -m owner --uid-owner "$CHILD_USERNAME" -j LOG --log-prefix "[QUOTA_TIME] " 2>/dev/null || \
        iptables -A QUOTA_TIME -m owner --uid-owner "$CHILD_USERNAME" -j LOG --log-prefix "[QUOTA_TIME] "
}

# Main
case "${1:-}" in
    track)
        init_iptables
        track_quota
        ;;
    reset)
        init_iptables
        reset_quota
        ;;
    whitelist)
        init_iptables
        generate_whitelist
        ;;
    *)
        echo "Usage: $0 {track|reset|whitelist}"
        exit 1
        ;;
esac

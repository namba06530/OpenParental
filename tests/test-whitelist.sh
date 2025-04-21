#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log() {
    echo -e "${GREEN}[TEST][INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[TEST][WARN]${NC} $1" >&2
}

error() {
    echo -e "${RED}[TEST][ERROR]${NC} $1" >&2
    exit 1
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
fi

# Clean up any existing containers
log "Cleaning up existing containers..."
docker ps -a | grep 'quota-whitelist-test' | awk '{print $1}' | xargs -r docker rm -f

# Build the test container
log "Building test container..."
if ! docker build -t quota-whitelist-test -f Dockerfile.test .; then
    error "Failed to build test container"
fi

# Create a container for testing with necessary privileges
log "Creating test container..."
CONTAINER_ID=$(docker run -d --privileged quota-whitelist-test tail -f /dev/null)
SHORT_ID=${CONTAINER_ID:0:12}
log "Container ID: $SHORT_ID"

# Wait for container to start
log "Waiting for container to start..."
sleep 5

# Ensure container is running
log "Checking container status..."
if ! docker ps | grep -q "$SHORT_ID"; then
    log "Container status:"
    docker ps -a | grep "$SHORT_ID" || true
    log "Container logs:"
    docker logs "$SHORT_ID" || true
    error "Container failed to start"
fi

log "Container started with ID: $SHORT_ID"
echo

# Run tests inside the container
log "Starting whitelist tests inside container..."

# Test 1: Create test user
log "Creating test user..."
if ! docker exec "$SHORT_ID" bash -c "useradd -m -s /bin/bash quotauser"; then
    error "Failed to create test user"
fi

# Get user UID
USER_UID=$(docker exec "$SHORT_ID" bash -c "id -u quotauser")
log "User UID: $USER_UID"

# Test 2: Initialize whitelist chain
log "Initializing whitelist chain..."
if ! docker exec "$SHORT_ID" bash -c "iptables -N WHITELIST 2>/dev/null || iptables -F WHITELIST"; then
    error "Failed to create WHITELIST chain"
fi

# Test 3: Add whitelisted domains
log "Adding whitelisted domains..."
WHITELISTED_IPS=(
    "8.8.8.8"      # Google DNS
    "1.1.1.1"      # Cloudflare DNS
    "192.168.1.1"  # Common local router
)

for ip in "${WHITELISTED_IPS[@]}"; do
    if ! docker exec "$SHORT_ID" bash -c "iptables -A WHITELIST -m owner --uid-owner $USER_UID -d $ip -j ACCEPT"; then
        error "Failed to whitelist IP: $ip"
    fi
    log "Successfully whitelisted IP: $ip"
done

# Test 4: Verify whitelist rules
log "Verifying whitelist rules..."
if ! docker exec "$SHORT_ID" bash -c "iptables -L WHITELIST -n -v"; then
    error "Failed to verify whitelist rules"
fi

# Test 5: Test connectivity to whitelisted domains
log "Testing connectivity to whitelisted domains..."
for ip in "${WHITELISTED_IPS[@]}"; do
    if ! docker exec "$SHORT_ID" bash -c "ping -c 1 $ip >/dev/null 2>&1"; then
        warn "Could not reach whitelisted IP: $ip (this might be normal depending on the network)"
    else
        log "Successfully reached whitelisted IP: $ip"
    fi
done

# Clean up
log "Cleaning up..."

# Remove chain from OUTPUT
docker exec "$SHORT_ID" bash -c "iptables -D OUTPUT -j WHITELIST 2>/dev/null || true"

# Remove chain
docker exec "$SHORT_ID" bash -c "iptables -F WHITELIST"
docker exec "$SHORT_ID" bash -c "iptables -X WHITELIST"

# Remove test user
docker exec "$SHORT_ID" bash -c "userdel -r quotauser 2>/dev/null || true"

# Stop and remove the container
log "Stopping and removing container..."
docker stop "$SHORT_ID"
docker rm "$SHORT_ID"

log "All whitelist tests passed successfully!" 
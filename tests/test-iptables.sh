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
docker ps -a | grep 'quota-iptables-test' | awk '{print $1}' | xargs -r docker rm -f

# Build the test container
log "Building test container..."
if ! docker build -t quota-iptables-test -f Dockerfile.test .; then
    error "Failed to build test container"
fi

# Create a container for testing with necessary privileges
log "Creating test container..."
CONTAINER_ID=$(docker run -d --privileged quota-iptables-test tail -f /dev/null)
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
log "Starting iptables tests inside container..."

# Test 1: Create test user
log "Creating test user..."
if ! docker exec "$SHORT_ID" bash -c "useradd -m -s /bin/bash quotauser"; then
    error "Failed to create test user"
fi

# Get user UID
USER_UID=$(docker exec "$SHORT_ID" bash -c "id -u quotauser")
log "User UID: $USER_UID"

# Test 2: Initialize iptables chains
log "Initializing iptables chains..."
if ! docker exec "$SHORT_ID" bash -c "iptables -N QUOTA_TIME 2>/dev/null || iptables -F QUOTA_TIME"; then
    error "Failed to create QUOTA_TIME chain"
fi

if ! docker exec "$SHORT_ID" bash -c "iptables -A QUOTA_TIME -m owner --uid-owner $USER_UID -j LOG --log-prefix '[QUOTA_TIME] '"; then
    error "Failed to add rule to QUOTA_TIME chain"
fi

if ! docker exec "$SHORT_ID" bash -c "iptables -N WHITELIST 2>/dev/null || iptables -F WHITELIST"; then
    error "Failed to create WHITELIST chain"
fi

if ! docker exec "$SHORT_ID" bash -c "iptables -A WHITELIST -m owner --uid-owner $USER_UID -d '8.8.8.8' -j ACCEPT"; then
    error "Failed to add rule to WHITELIST chain"
fi

if ! docker exec "$SHORT_ID" bash -c "iptables -C OUTPUT -j WHITELIST 2>/dev/null || iptables -I OUTPUT 1 -j WHITELIST"; then
    error "Failed to add WHITELIST chain to OUTPUT"
fi

if ! docker exec "$SHORT_ID" bash -c "iptables -C OUTPUT -j QUOTA_TIME 2>/dev/null || iptables -A OUTPUT -j QUOTA_TIME"; then
    error "Failed to add QUOTA_TIME chain to OUTPUT"
fi

# Test 3: Check QUOTA_TIME chain
log "Checking QUOTA_TIME chain..."
if ! docker exec "$SHORT_ID" bash -c "iptables -L QUOTA_TIME >/dev/null 2>&1"; then
    error "QUOTA_TIME chain not found"
fi

# Test 4: Check WHITELIST chain
log "Checking WHITELIST chain..."
if ! docker exec "$SHORT_ID" bash -c "iptables -L WHITELIST >/dev/null 2>&1"; then
    error "WHITELIST chain not found"
fi

# Test 5: Check rules for test user
log "Checking user-specific rules..."
if ! docker exec "$SHORT_ID" bash -c "iptables-save | grep -q 'owner --uid-owner $USER_UID'"; then
    error "User-specific rules not found"
fi

# Clean up
log "Cleaning up..."

# Remove chains from OUTPUT
docker exec "$SHORT_ID" bash -c "iptables -D OUTPUT -j WHITELIST 2>/dev/null || true"
docker exec "$SHORT_ID" bash -c "iptables -D OUTPUT -j QUOTA_TIME 2>/dev/null || true"

# Remove chains
docker exec "$SHORT_ID" bash -c "iptables -F WHITELIST"
docker exec "$SHORT_ID" bash -c "iptables -X WHITELIST"
docker exec "$SHORT_ID" bash -c "iptables -F QUOTA_TIME"
docker exec "$SHORT_ID" bash -c "iptables -X QUOTA_TIME"

# Remove test user
docker exec "$SHORT_ID" bash -c "userdel -r quotauser 2>/dev/null || true"

# Stop and remove the container
log "Stopping and removing container..."
docker stop "$SHORT_ID"
docker rm "$SHORT_ID"

log "All iptables tests passed successfully!" 
#!/bin/bash
set -euo pipefail

# Common utility functions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN]${NC} $1" >&2
}

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source .env file
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    log_error "Configuration file not found at $PROJECT_ROOT/.env"
    exit 1
fi
source "$PROJECT_ROOT/.env"

# Build test container
log "Building test container..."
docker build -t openparental-test -f "$PROJECT_ROOT/tests/Dockerfile.test" "$PROJECT_ROOT"

# Run test container
log "Starting test container..."
CONTAINER_ID=$(docker run -d openparental-test)

# Wait for container to be ready
sleep 2

# Function to run a test
run_test() {
    local name="$1"
    local command="$2"
    
    log "Running test: $name"
    if eval "$command"; then
        log "Test passed: $name"
        return 0
    else
        log_error "Test failed: $name"
        return 1
    fi
}

# Test 1: Check if quota script exists
run_test "Quota Script Existence" \
    "docker exec $CONTAINER_ID test -f /usr/local/bin/internet-quota.sh"

# Test 2: Check if quota script is executable
run_test "Quota Script Executable" \
    "docker exec $CONTAINER_ID test -x /usr/local/bin/internet-quota.sh"

# Test 3: Check if quota directory exists
run_test "Quota Directory Existence" \
    "docker exec $CONTAINER_ID test -d /var/lib/openparental/quota"

# Test 4: Test quota reset
run_test "Quota Reset" \
    "docker exec $CONTAINER_ID bash -c 'touch /var/lib/openparental/quota/child.log && /usr/local/bin/internet-quota.sh reset'"

# Test 5: Test quota tracking
run_test "Quota Tracking" \
    "docker exec $CONTAINER_ID bash -c '/usr/local/bin/internet-quota.sh track'"

# Test 6: Test quota status
run_test "Quota Status" \
    "docker exec $CONTAINER_ID bash -c '/usr/local/bin/internet-quota.sh status'"

# Cleanup
log "Cleaning up..."
docker stop "$CONTAINER_ID"
docker rm "$CONTAINER_ID"

log "All tests completed!" 
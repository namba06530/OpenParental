#!/bin/bash
set -euo pipefail

# =============================================================================
# Basic Logging System Test
# =============================================================================
# This script tests the fundamental features of the logging system:
# - Creation and initialization of log files
# - Log writing and rotation
# - Log cleanup and management
# - Log status verification
#
# This test focuses on the logging infrastructure rather than specific
# log message content.
# =============================================================================

# Loading the logging library
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../src/lib/logging.sh"

# Test configuration
TEST_MODULE="test"
TEST_LOG_DIR="/tmp/openparental-test"
LOG_DIR="$TEST_LOG_DIR"
LOG_MAX_SIZE=100  # 100 bytes for testing
LOG_MAX_FILES=2   # 2 files for testing
QUOTA_LOG="$LOG_DIR/quota.log"
DEBUG_LOG="$LOG_DIR/debug.log"
SECURITY_LOG="$LOG_DIR/security.log"

# Cleanup function
cleanup() {
    rm -rf "$TEST_LOG_DIR"
}

# Error handling
trap cleanup EXIT

# Test 1: Initialization
echo "Test 1: Logging system initialization"
init_logging "$TEST_MODULE"
if [ ! -d "$LOG_DIR" ]; then
    echo "❌ Failed: Log directory was not created"
    exit 1
fi
echo "✅ Success: Log directory was created"

# Test 2: Log writing
echo -e "\nTest 2: Log writing"
log_debug "$TEST_MODULE" "test" "Debug message"
log_info "$TEST_MODULE" "test" "Info message"
log_warn "$TEST_MODULE" "test" "Warning message"
log_error "$TEST_MODULE" "test" "Error message"
log_security "$TEST_MODULE" "test" "Security message"

# File verification
for log_file in "$QUOTA_LOG" "$DEBUG_LOG" "$SECURITY_LOG"; do
    if [ ! -f "$log_file" ]; then
        echo "❌ Failed: File $log_file does not exist"
        exit 1
    fi
    echo "✅ Success: File $log_file exists"
done

# Test 3: Log rotation
echo -e "\nTest 3: Log rotation"
# Generate logs to exceed maximum size
for i in {1..10}; do
    log_debug "$TEST_MODULE" "test" "Test message long enough to exceed size limit $i"
done

# Rotation verification
sleep 1  # Wait for rotation to complete
if ls "${DEBUG_LOG}."*".gz" >/dev/null 2>&1; then
    echo "✅ Success: Log rotation works"
else
    echo "❌ Failed: Log rotation did not work"
    echo "Log directory contents:"
    ls -la "$LOG_DIR"
    echo "Debug file size:"
    wc -c < "$DEBUG_LOG"
    exit 1
fi

# Test 4: Log cleanup
echo -e "\nTest 4: Log cleanup"
cleanup_logs "$TEST_MODULE" "$DEBUG_LOG"
if [ -f "${DEBUG_LOG}.2.gz" ]; then
    echo "❌ Failed: Old logs were not cleaned up"
    exit 1
fi
echo "✅ Success: Log cleanup works"

# Test 5: Log status verification
echo -e "\nTest 5: Log status verification"
if check_log_status "$TEST_MODULE" "$DEBUG_LOG"; then
    echo "✅ Success: Log status verification works"
else
    echo "❌ Failed: Log status verification failed"
    exit 1
fi

echo -e "\n✨ All tests passed successfully!"
exit 0 
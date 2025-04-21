#!/bin/bash
set -euo pipefail

# =============================================================================
# Error Handling Module Test
# =============================================================================
# This script tests the error handling module and its integration with
# the logging system. It verifies:
# - Correct formatting of different error types
# - Permission error handling
# - Configuration error handling
# - Network error handling
# - Cryptographic error handling
# - Quota error handling
# - System error handling
# - Error cleanup
#
# This test focuses on error message quality and format rather than
# the logging infrastructure itself.
# =============================================================================

# Verify we are in a Docker container
if [ ! -f /.dockerenv ]; then
    echo "❌ This script must be run in a Docker container"
    echo "Use the command: docker run --rm -v \"\$PWD\":/app -w /app ubuntu:22.04 bash ./tests/test-error-handling-module.sh"
    exit 1
fi

# Import error handling module
source "$(dirname "$0")/../src/error-handling.sh"

# Test variables
TEST_LOG_FILE="/tmp/test_errors.log"

# Test function for error logging
test_error_logging() {
    local test_name="Error logging test"
    local success=true
    
    # Test with valid error type
    log_error "PERMISSION" "Test permission error" 1
    if ! grep -q "\[PERMISSION\].*Test permission error" "$ERROR_LOG_FILE"; then
        echo "❌ $test_name: Incorrect log format for permission error"
        success=false
    fi
    
    # Test with invalid error type
    log_error "INVALID" "Test invalid error" 1
    if ! grep -q "\[SYSTEM\].*Test invalid error" "$ERROR_LOG_FILE"; then
        echo "❌ $test_name: Incorrect log format for invalid error"
        success=false
    fi
    
    if [ "$success" = true ]; then
        echo "✅ $test_name: Success"
        return 0
    else
        return 1
    fi
}

# Test function for permission error handling
test_permission_handling() {
    local test_name="Permission error handling test"
    local success=true
    
    # Test with protected file
    touch /tmp/test_protected
    chmod 000 /tmp/test_protected
    
    handle_permission_error "read" "/tmp/test_protected" "testuser"
    if ! grep -q "\[PERMISSION\].*Access denied.*read.*test_protected.*testuser" "$ERROR_LOG_FILE"; then
        echo "❌ $test_name: Incorrect log format for permission error"
        success=false
    fi
    
    # Cleanup
    chmod 644 /tmp/test_protected
    rm /tmp/test_protected
    
    if [ "$success" = true ]; then
        echo "✅ $test_name: Success"
        return 0
    else
        return 1
    fi
}

# Test function for configuration error handling
test_config_handling() {
    local test_name="Configuration error handling test"
    local success=true
    
    # Test with missing file
    handle_config_error "/tmp/nonexistent.conf" "Missing file"
    if ! grep -q "\[CONFIG\].*Configuration file missing.*nonexistent.conf" "$ERROR_LOG_FILE"; then
        echo "❌ $test_name: Incorrect log format for missing file"
        success=false
    fi
    
    # Test with existing file
    touch /tmp/test.conf
    handle_config_error "/tmp/test.conf" "Syntax error"
    if ! grep -q "\[CONFIG\].*Configuration error.*test.conf.*Syntax error" "$ERROR_LOG_FILE"; then
        echo "❌ $test_name: Incorrect log format for syntax error"
        success=false
    fi
    
    # Cleanup
    rm /tmp/test.conf
    
    if [ "$success" = true ]; then
        echo "✅ $test_name: Success"
        return 0
    else
        return 1
    fi
}

# Test function for network error handling
test_network_handling() {
    local test_name="Network error handling test"
    local success=true
    
    handle_network_error "connection" "example.com" "Timeout"
    if ! grep -q "\[NETWORK\].*Network error.*connection.*example.com.*Timeout" "$ERROR_LOG_FILE"; then
        echo "❌ $test_name: Incorrect log format for network error"
        success=false
    fi
    
    if [ "$success" = true ]; then
        echo "✅ $test_name: Success"
        return 0
    else
        return 1
    fi
}

# Test function for cryptographic error handling
test_crypto_handling() {
    local test_name="Cryptographic error handling test"
    local success=true
    
    handle_crypto_error "encryption" "Invalid key"
    if ! grep -q "\[CRYPTO\].*Cryptographic error.*encryption.*Invalid key" "$ERROR_LOG_FILE"; then
        echo "❌ $test_name: Incorrect log format for cryptographic error"
        success=false
    fi
    
    if [ "$success" = true ]; then
        echo "✅ $test_name: Success"
        return 0
    else
        return 1
    fi
}

# Test function for quota error handling
test_quota_handling() {
    local test_name="Quota error handling test"
    local success=true
    
    handle_quota_error "testuser" "download" "Quota exceeded"
    if ! grep -q "\[QUOTA\].*Quota error.*testuser.*download.*Quota exceeded" "$ERROR_LOG_FILE"; then
        echo "❌ $test_name: Incorrect log format for quota error"
        success=false
    fi
    
    if [ "$success" = true ]; then
        echo "✅ $test_name: Success"
        return 0
    else
        return 1
    fi
}

# Test function for system error handling
test_system_handling() {
    local test_name="System error handling test"
    local success=true
    
    handle_system_error "initialization" "Initialization failed"
    if ! grep -q "\[SYSTEM\].*System error.*initialization.*Initialization failed" "$ERROR_LOG_FILE"; then
        echo "❌ $test_name: Incorrect log format for system error"
        success=false
    fi
    
    if [ "$success" = true ]; then
        echo "✅ $test_name: Success"
        return 0
    else
        return 1
    fi
}

# Test function for error cleanup
test_cleanup() {
    local test_name="Error cleanup test"
    local success=true
    
    # Create temporary file
    touch /tmp/test_cleanup
    
    # Test cleanup
    cleanup_on_error 1 "rm -f /tmp/test_cleanup"
    
    # Verify file was deleted
    if [ -f "/tmp/test_cleanup" ]; then
        echo "❌ $test_name: Temporary file was not deleted"
        success=false
    fi
    
    if [ "$success" = true ]; then
        echo "✅ $test_name: Success"
        return 0
    else
        return 1
    fi
}

# Test function for prerequisites verification
test_prerequisites() {
    local test_name="Prerequisites verification test"
    local success=true
    
    if ! check_prerequisites; then
        echo "❌ $test_name: Prerequisites verification failed"
        success=false
    fi
    
    if [ "$success" = true ]; then
        echo "✅ $test_name: Success"
        return 0
    else
        return 1
    fi
}

# Main function
main() {
    echo "🧪 Starting error handling module tests..."
    
    # Module initialization
    if ! init_error_handling; then
        echo "❌ Failed to initialize error handling module"
        return 1
    fi
    
    # Run tests
    local total_tests=9
    local failed_tests=0
    
    test_error_logging || ((failed_tests++))
    test_permission_handling || ((failed_tests++))
    test_config_handling || ((failed_tests++))
    test_network_handling || ((failed_tests++))
    test_crypto_handling || ((failed_tests++))
    test_quota_handling || ((failed_tests++))
    test_system_handling || ((failed_tests++))
    test_cleanup || ((failed_tests++))
    test_prerequisites || ((failed_tests++))
    
    # Display summary
    echo "📊 Test summary:"
    echo "- Tests executed: $total_tests"
    echo "- Tests failed: $failed_tests"
    echo "- Tests passed: $((total_tests - failed_tests))"
    
    return "$failed_tests"
}

# Script execution
main "$@" 
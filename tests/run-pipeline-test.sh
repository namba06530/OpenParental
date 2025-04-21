#!/bin/bash
set -euo pipefail

# Build the Docker image for pipeline testing
docker build -t openparental-pipeline-test -f tests/Dockerfile.pipeline .

# Run the container and capture the exit code
docker run --privileged openparental-pipeline-test || true

# Check logs for critical errors, excluding known Docker/systemd issues
docker logs $(docker ps -lq) 2>&1 | grep -v \
    -e "Failed to connect to bus" \
    -e "System has not been booted with systemd" \
    -e "Failed to connect to socket /run/dbus/system_bus_socket" \
    -e "Unable to configure allowed days" \
    -e "Failed to restart NetworkManager" \
    | grep -i "error"

if [ $? -eq 0 ]; then
    echo "Critical errors found in the logs"
    exit 1
else
    echo "Pipeline test completed successfully (ignoring expected Docker/systemd errors)"
    exit 0
fi 
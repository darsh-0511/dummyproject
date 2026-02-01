#!/bin/bash

set -e

echo "⏪ Starting Rollback Process..."

# Configuration
BACKUP_DIR="/opt/blu-reserve/backups"
COMPOSE_FILE="podman-compose.yml"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if backup exists
if [ ! -f "${BACKUP_DIR}/latest_deployment.txt" ]; then
    print_error "No previous deployment found!"
    exit 1
fi

# Read previous deployment info
print_status "Reading previous deployment information..."
cat ${BACKUP_DIR}/latest_deployment.txt

# Get previous build tag
PREVIOUS_TAG=$(grep "Build Tag:" ${BACKUP_DIR}/latest_deployment.txt | cut -d' ' -f3)

if [ -z "$PREVIOUS_TAG" ]; then
    print_error "Could not determine previous build tag!"
    exit 1
fi

print_status "Rolling back to build: ${PREVIOUS_TAG}"

# Stop current containers
print_status "Stopping current containers..."
podman-compose down

# Pull previous images
print_status "Pulling previous images..."
podman pull ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/blu-reserve-backend:${PREVIOUS_TAG}
podman pull ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/blu-reserve-frontend:${PREVIOUS_TAG}

# Tag as latest
podman tag ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/blu-reserve-backend:${PREVIOUS_TAG} blu-reserve-backend:latest
podman tag ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/blu-reserve-frontend:${PREVIOUS_TAG} blu-reserve-frontend:latest

# Start containers with previous version
print_status "Starting containers with previous version..."
podman-compose up -d

# Wait and check health
sleep 15
./health-check.sh

if [ $? -eq 0 ]; then
    print_status "✅ Rollback completed successfully!"
else
    print_error "❌ Rollback health check failed!"
    exit 1
fi

exit 0

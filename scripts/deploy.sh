#!/bin/bash

set -e

echo "🚀 Starting Blu-Reserve Deployment..."

# Configuration
COMPOSE_FILE="podman-compose.yml"
ENV_FILE=".env.production"
BACKUP_DIR="/opt/blu-reserve/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create backup directory
mkdir -p ${BACKUP_DIR}

# Backup current deployment
print_status "Creating backup of current deployment..."
if podman ps -a | grep -q blu-reserve; then
    podman-compose ps > ${BACKUP_DIR}/deployment_${TIMESTAMP}.txt
    print_status "Backup created: ${BACKUP_DIR}/deployment_${TIMESTAMP}.txt"
fi

# Pull latest images
print_status "Pulling latest container images..."
echo ${REGISTRY_CREDENTIALS_PSW} | podman login ${REGISTRY_URL} -u ${REGISTRY_CREDENTIALS_USR} --password-stdin

podman pull ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/blu-reserve-backend:${BUILD_TAG}
podman pull ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/blu-reserve-frontend:${BUILD_TAG}

podman logout ${REGISTRY_URL}

# Tag images as latest
podman tag ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/blu-reserve-backend:${BUILD_TAG} blu-reserve-backend:latest
podman tag ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/blu-reserve-frontend:${BUILD_TAG} blu-reserve-frontend:latest

# Stop existing containers
print_status "Stopping existing containers..."
podman-compose down || true

# Remove old containers
print_status "Removing old containers..."
podman rm -f blu-reserve-backend blu-reserve-frontend 2>/dev/null || true

# Start new containers
print_status "Starting new containers..."
podman-compose --env-file ${ENV_FILE} up -d

# Wait for containers to be healthy
print_status "Waiting for containers to be healthy..."
sleep 15

# Check container status
print_status "Checking container status..."
podman-compose ps

# Verify containers are running
if ! podman ps | grep -q blu-reserve-backend; then
    print_error "Backend container is not running!"
    exit 1
fi

if ! podman ps | grep -q blu-reserve-frontend; then
    print_error "Frontend container is not running!"
    exit 1
fi

print_status "✅ Deployment completed successfully!"
print_status "Backend: http://localhost:8000"
print_status "Frontend: http://localhost:8080"

# Save deployment info
echo "Deployment Time: ${TIMESTAMP}" > ${BACKUP_DIR}/latest_deployment.txt
echo "Build Tag: ${BUILD_TAG}" >> ${BACKUP_DIR}/latest_deployment.txt
echo "Backend Image: ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/blu-reserve-backend:${BUILD_TAG}" >> ${BACKUP_DIR}/latest_deployment.txt
echo "Frontend Image: ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/blu-reserve-frontend:${BUILD_TAG}" >> ${BACKUP_DIR}/latest_deployment.txt

exit 0

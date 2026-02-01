#!/bin/bash

set -e

echo "🏥 Running Health Checks..."

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

BACKEND_URL="http://localhost:8000"
FRONTEND_URL="http://localhost:8080"
MAX_RETRIES=10
RETRY_DELAY=5

# Function to check endpoint
check_endpoint() {
    local url=$1
    local name=$2
    local retries=0
    
    echo "Checking ${name}..."
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -f -s -o /dev/null -w "%{http_code}" ${url} | grep -q "200"; then
            echo -e "${GREEN}✅ ${name} is healthy${NC}"
            return 0
        fi
        
        retries=$((retries + 1))
        echo "Retry ${retries}/${MAX_RETRIES} for ${name}..."
        sleep ${RETRY_DELAY}
    done
    
    echo -e "${RED}❌ ${name} health check failed${NC}"
    return 1
}

# Check backend health
check_endpoint "${BACKEND_URL}/seats" "Backend API"
BACKEND_STATUS=$?

# Check frontend health
check_endpoint "${FRONTEND_URL}/" "Frontend"
FRONTEND_STATUS=$?

# Check container status
echo ""
echo "Container Status:"
podman ps --filter "name=blu-reserve" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check container logs for errors
echo ""
echo "Recent Backend Logs:"
podman logs --tail 20 blu-reserve-backend

echo ""
echo "Recent Frontend Logs:"
podman logs --tail 20 blu-reserve-frontend

# Overall health status
if [ $BACKEND_STATUS -eq 0 ] && [ $FRONTEND_STATUS -eq 0 ]; then
    echo -e "\n${GREEN}✅ All health checks passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Health checks failed!${NC}"
    exit 1
fi

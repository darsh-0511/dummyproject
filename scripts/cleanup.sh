#!/bin/bash

echo "🧹 Cleaning up old containers and images..."

# Stop and remove all blu-reserve containers
podman stop $(podman ps -a -q --filter "name=blu-reserve") 2>/dev/null || true
podman rm $(podman ps -a -q --filter "name=blu-reserve") 2>/dev/null || true

# Remove dangling images
podman image prune -f

# Remove old images (keep last 3 versions)
podman images | grep blu-reserve | tail -n +4 | awk '{print $3}' | xargs -r podman rmi -f

# Clean up volumes
podman volume prune -f

echo "✅ Cleanup completed!"

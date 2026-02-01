# Build and Run Instructions

## Local Development with Podman

### Build Images
```bash
# Build backend
podman build -t blu-reserve-backend:latest -f backend/Containerfile backend/

# Build frontend
podman build -t blu-reserve-frontend:latest -f frontend/Containerfile frontend/

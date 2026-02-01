# Stage 1: Build the React application
FROM registry.access.redhat.com/ubi8/nodejs-20:latest AS builder

# Switch to root to set permissions
USER root

WORKDIR /app

# Set proper ownership for the app directory
RUN chown -R 1001:0 /app && \
    chmod -R g+rwX /app

# Switch back to non-root user
USER 1001

# Copy package files
COPY --chown=1001:0 package*.json ./

# Install dependencies (including dev dependencies for build)
RUN npm ci

# Copy source code
COPY --chown=1001:0 . .

# Build the application
RUN npm run build

# Stage 2: Serve with Nginx
FROM registry.access.redhat.com/ubi8/nginx-122:latest

# Switch to root for configuration
USER root

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Set proper permissions for nginx
RUN chown -R 1001:0 /usr/share/nginx/html && \
    chmod -R g+rwX /usr/share/nginx/html && \
    chown -R 1001:0 /var/log/nginx /var/lib/nginx /run && \
    chmod -R g+rwX /var/log/nginx /var/lib/nginx /run

# Switch back to non-root user
USER 1001

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Run nginx
CMD ["nginx", "-g", "daemon off;"]

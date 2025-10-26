FROM alpine:latest

# Install dependencies
RUN apk add --no-cache \
    git \
    bash \
    findutils \
    coreutils

# Create service user
RUN addgroup -g 1000 autoinit && \
    adduser -D -u 1000 -G autoinit autoinit

# Set working directory
WORKDIR /app

# Copy service files
COPY auto-init.sh /app/
COPY templates/ /app/templates/

# Make script executable
RUN chmod +x /app/auto-init.sh

# Default environment variables
ENV GIT_USER_NAME="AtomicQMS Auto-Init" \
    GIT_USER_EMAIL="autoinit@atomicqms.local" \
    REPO_ROOT="/data/git/repositories" \
    CHECK_INTERVAL=300

# Create entrypoint script for periodic execution
RUN echo '#!/bin/bash' > /app/entrypoint.sh && \
    echo 'echo "AtomicQMS Auto-Init Service Starting..."' >> /app/entrypoint.sh && \
    echo 'echo "Check interval: ${CHECK_INTERVAL} seconds"' >> /app/entrypoint.sh && \
    echo 'while true; do' >> /app/entrypoint.sh && \
    echo '  /app/auto-init.sh' >> /app/entrypoint.sh && \
    echo '  echo "Sleeping for ${CHECK_INTERVAL} seconds..."' >> /app/entrypoint.sh && \
    echo '  sleep ${CHECK_INTERVAL}' >> /app/entrypoint.sh && \
    echo 'done' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

# Switch to service user
USER autoinit

# Run the service
CMD ["/app/entrypoint.sh"]

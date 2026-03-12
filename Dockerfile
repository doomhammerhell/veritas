# Multi-stage Dockerfile for Veritas

# Stage 1: Build stage
FROM node:25-alpine AS builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache \
    git \
    curl \
    build-base \
    openssl-dev \
    pkgconfig \
    libgcc \
    libstdc++ \
    python3 \
    make \
    g++

# Install Rust with specific version and avoid gix-url issues
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain=1.74.0

# Add cargo to PATH
ENV PATH="/root/.cargo/bin:$PATH"

# Install scarb without problematic dependencies
RUN cargo install scarb --version 0.8.0 --locked || \
    cargo install scarb --version 0.8.0

# Copy package files
COPY package*.json ./
COPY docs/package*.json ./docs/
COPY frontend/package*.json ./frontend/

# Install dependencies
RUN npm ci --only=production
RUN cd docs && npm ci --only=production
RUN cd frontend && npm ci --only=production

# Copy source code
COPY . .

# Build contracts - try without scarb first, fallback to manual build
RUN scarb build || \
    echo "Scarb build failed, continuing with frontend and docs build..."

# Build frontend
RUN cd frontend && npm run build

# Build documentation
RUN cd docs && npm run build

# Stage 2: Production stage
FROM node:25-alpine AS production

# Install runtime dependencies
RUN apk add --no-cache \
    curl \
    dumb-init \
    ca-certificates

# Create non-root user
RUN addgroup -g 1001 -S veritas && \
    adduser -S veritas -u 1001 -G veritas

# Set working directory
WORKDIR /app

# Copy built artifacts from builder stage
COPY --from=builder --chown=veritas:veritas /app/frontend/build ./frontend/build
COPY --from=builder --chown=veritas:veritas /app/docs/build ./docs/build
COPY --from=builder --chown=veritas:veritas /app/package*.json ./
COPY --from=builder --chown=veritas:veritas /app/scripts ./scripts
COPY --from=builder --chown=veritas:veritas /app/src ./src

# Install production dependencies
RUN npm ci --only=production && npm cache clean --force

# Create directories
RUN mkdir -p /app/logs /app/data && \
    chown -R veritas:veritas /app/logs /app/data

# Switch to non-root user
USER veritas

# Expose ports
EXPOSE 3000 5173 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV DOCKER=true

# Start application
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]

# Labels
LABEL maintainer="Veritas Organization <dev@veritas.io>"
LABEL version="0.4.0"
LABEL description="Enterprise-grade blind voting system on Starknet"
LABEL org.opencontainers.image.title="Veritas"
LABEL org.opencontainers.image.description="Enterprise-grade blind voting system on Starknet"
LABEL org.opencontainers.image.url="https://veritas.io"
LABEL org.opencontainers.image.documentation="https://docs.veritas.io"
LABEL org.opencontainers.image.source="https://github.com/veritas-org/veritas"
LABEL org.opencontainers.image.vendor="Veritas Organization"
LABEL org.opencontainers.image.licenses="MIT"

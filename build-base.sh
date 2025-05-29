#!/bin/bash
set -e

echo "🔍 Testing Alpine package availability..."

# Test which packages are available
test_packages() {
    local temp_container=$(docker run -d --rm ruby:3.3.0-alpine sleep 60)

    echo "Testing package availability..."

    # Core packages (should always work)
    docker exec $temp_container apk add --no-cache \
        build-base gcc g++ make musl-dev linux-headers \
        curl curl-dev openssl-dev ca-certificates \
        git bash tzdata unzip file \
        postgresql-client postgresql-dev libpq-dev \
        sqlite sqlite-dev \
        imagemagick imagemagick-dev libjpeg-turbo \
        freetype freetype-dev \
        nodejs npm yarn \
        libgomp dumb-init \
        libxml2-dev libxslt-dev zlib-dev libffi-dev yaml-dev \
        python3 python3-dev

    echo "✅ Core packages installed successfully"

    # Test optional packages
    echo "Testing optional packages..."

    # Test mimalloc variations
    if docker exec $temp_container apk add --no-cache mimalloc2 mimalloc2-dev 2>/dev/null; then
        echo "✅ mimalloc2 available"
        MIMALLOC_PKG="mimalloc2 mimalloc2-dev"
    elif docker exec $temp_container apk add --no-cache mimalloc mimalloc-dev 2>/dev/null; then
        echo "✅ mimalloc available"
        MIMALLOC_PKG="mimalloc mimalloc-dev"
    else
        echo "❌ mimalloc not available"
        MIMALLOC_PKG=""
    fi

    # Test MariaDB vs MySQL
    if docker exec $temp_container apk add --no-cache mariadb-connector-c mariadb-dev 2>/dev/null; then
        echo "✅ MariaDB packages available"
        MYSQL_PKG="mariadb-connector-c mariadb-dev"
    elif docker exec $temp_container apk add --no-cache mysql-client mysql-dev 2>/dev/null; then
        echo "✅ MySQL packages available"
        MYSQL_PKG="mysql-client mysql-dev"
    else
        echo "❌ No MySQL packages available"
        MYSQL_PKG=""
    fi

    # Test additional image processing
    if docker exec $temp_container apk add --no-cache libwebp libwebp-dev 2>/dev/null; then
        echo "✅ WebP packages available"
        WEBP_PKG="libwebp libwebp-dev"
    else
        echo "❌ WebP packages not available"
        WEBP_PKG=""
    fi

    docker stop $temp_container

    # Generate optimized Dockerfile
    generate_dockerfile
}

generate_dockerfile() {
    cat > Dockerfile.base.optimized << 'EOF'
# Optimized Base Image - Generated based on available packages
FROM ruby:3.3.0-alpine

LABEL maintainer="your-email@example.com"
LABEL description="Optimized Ruby Rails base image"
LABEL version="1.0"

# Update package database
RUN apk update --no-cache && apk upgrade --no-cache

# Install core packages (guaranteed to work)
RUN apk add --no-cache \
    build-base \
    gcc \
    g++ \
    make \
    musl-dev \
    linux-headers \
    curl \
    curl-dev \
    openssl-dev \
    ca-certificates \
    git \
    bash \
    tzdata \
    unzip \
    file \
    postgresql-client \
    postgresql-dev \
    libpq-dev \
    sqlite \
    sqlite-dev \
    imagemagick \
    imagemagick-dev \
    libjpeg-turbo \
    freetype \
    freetype-dev \
    nodejs \
    npm \
    yarn \
    libgomp \
    dumb-init \
    libxml2-dev \
    libxslt-dev \
    zlib-dev \
    libffi-dev \
    yaml-dev \
    python3 \
    python3-dev
EOF

    # Add optional packages if available
    if [ -n "$MIMALLOC_PKG" ]; then
        cat >> Dockerfile.base.optimized << EOF

# Install mimalloc for better memory management
RUN apk add --no-cache $MIMALLOC_PKG
EOF
    fi

    if [ -n "$MYSQL_PKG" ]; then
        cat >> Dockerfile.base.optimized << EOF

# Install MySQL/MariaDB support
RUN apk add --no-cache $MYSQL_PKG
EOF
    fi

    if [ -n "$WEBP_PKG" ]; then
        cat >> Dockerfile.base.optimized << EOF

# Install WebP support
RUN apk add --no-cache $WEBP_PKG
EOF
    fi

    cat >> Dockerfile.base.optimized << 'EOF'

# Clean up
RUN rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Configure Ruby environment
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV RUBY_YJIT_ENABLE=1
ENV MALLOC_ARENA_MAX=2
EOF

    if [ -n "$MIMALLOC_PKG" ]; then
        cat >> Dockerfile.base.optimized << 'EOF'

# Configure mimalloc
RUN if ls /usr/lib/libmimalloc* 1> /dev/null 2>&1; then \
        echo "export LD_PRELOAD=\$(ls /usr/lib/libmimalloc*.so* | head -1)" >> /etc/profile; \
    fi
EOF
    fi

    cat >> Dockerfile.base.optimized << 'EOF'

# Configure Bundler
RUN gem update --system --no-document && \
    gem install bundler -v 2.6.5 --no-document && \
    bundle config set --global jobs $(nproc) && \
    bundle config set --global retry 3 && \
    bundle config set --global timeout 30

# Pre-install common gems
RUN gem install --no-document \
    rails \
    pg \
    puma \
    bootsnap \
    image_processing

# Setup directories
RUN mkdir -p /app /tmp/rails && \
    chmod 755 /app /tmp/rails

WORKDIR /app

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD echo "healthy" || exit 1

CMD ["/bin/bash"]
EOF

    echo "✅ Generated optimized Dockerfile.base.optimized"
}

build_and_test() {
    echo "🏗️  Building optimized base image..."

    DOCKER_BUILDKIT=1 docker build \
        -f Dockerfile.base.optimized \
        -t rails-base:test \
        .

    echo "🧪 Testing base image..."

    # Test Ruby
    docker run --rm rails-base:test ruby --version

    # Test Node
    docker run --rm rails-base:test node --version

    # Test Bundler
    docker run --rm rails-base:test bundle --version

    # Test PostgreSQL client
    docker run --rm rails-base:test psql --version

    # Test ImageMagick
    docker run --rm rails-base:test convert --version

    echo "✅ All tests passed!"

    # Tag for pushing
    docker tag rails-base:test ghcr.io/sahilas/rails-base:latest

    echo "🚀 Ready to push: docker push ghcr.io/sahilas/rails-base:latest"
}

# Main execution
echo "🚀 Starting base image optimization..."
test_packages
build_and_test

echo "
📋 Summary:
- ✅ Generated Dockerfile.base.optimized with available packages
- ✅ Built and tested base image
- 🏷️  Tagged as ghcr.io/sahilas/rails-base:latest

Next steps:
1. Push the image: docker push ghcr.io/sahilas/rails-base:latest
2. Update your app Dockerfiles to use: FROM ghcr.io/sahilas/rails-base:latest
3. Enjoy super fast builds! 🚀
"
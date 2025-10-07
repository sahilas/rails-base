#!/bin/bash
# Bundle Install Fixes for Base Image Setup

echo "🔧 Bundle Install Fixes for Base Image Setup"

# Fix 1: Add platform to Gemfile.lock (run this locally first)
fix_gemfile_lock() {
    echo "🔒 Adding Linux platform to Gemfile.lock..."

    if [ -f "Gemfile.lock" ]; then
        # Add x86_64-linux platform if not present
        if ! grep -q "x86_64-linux" Gemfile.lock; then
            echo "Adding Linux platform..."
            bundle lock --add-platform x86_64-linux
            echo "✅ Linux platform added to Gemfile.lock"
        else
            echo "✅ Linux platform already present"
        fi
    else
        echo "❌ Gemfile.lock not found. Run 'bundle install' locally first."
        exit 1
    fi
}

# Fix 2: Create .bundle/config for consistent builds
create_bundle_config() {
    echo "📝 Creating .bundle/config..."

    mkdir -p .bundle
    cat > .bundle/config << 'EOF'
---
BUNDLE_JOBS: "4"
BUNDLE_RETRY: "5"
BUNDLE_TIMEOUT: "120"
BUNDLE_BUILD__SASSC: "--disable-march-tune-native"
BUNDLE_BUILD__FFI: "--enable-system-libffi"
BUNDLE_BUILD__NOKOGIRI: "--use-system-libraries"
BUNDLE_SILENCE_ROOT_WARNING: "true"
BUNDLE_DISABLE_PLATFORM_WARNINGS: "true"
EOF

    echo "✅ Created .bundle/config with optimized settings"
}

# Fix 3: Test bundle install with your base image
test_with_base_image() {
    echo "🧪 Testing bundle install with base image..."

    docker run --rm -it \
        -v $(pwd):/app \
        -w /app \
        ghcr.io/sahilas/rails-base:latest \
        sh -c "
            echo '=== Bundle Config ==='
            bundle config
            echo '=== Bundle Install Test ==='
            bundle install --verbose
            echo '=== Bundle Check ==='
            bundle check
        "
}

# Fix 4: Build with specific fixes for common gem issues
build_with_gem_fixes() {
    echo "💎 Building with gem-specific fixes..."

    # Create temporary Dockerfile with gem fixes
    cat > Dockerfile.gem-fixes << 'EOF'
FROM ghcr.io/sahilas/rails-base:latest

ENV RAILS_ENV=production
ENV BUNDLE_SILENCE_ROOT_WARNING=1

# Gem-specific build configurations
ENV BUNDLE_BUILD__SASSC="--disable-march-tune-native"
ENV BUNDLE_BUILD__FFI="--enable-system-libffi"
ENV BUNDLE_BUILD__NOKOGIRI="--use-system-libraries"
ENV BUNDLE_BUILD__PG="--with-pg-config=/usr/bin/pg_config"

WORKDIR /app

# Configure bundle with increased timeouts and retries
RUN bundle config set --global jobs $(nproc) && \
    bundle config set --global retry 5 && \
    bundle config set --global timeout 300 && \
    bundle config set --global without 'development test'

COPY Gemfile* ./

# Install with specific gem handling
RUN bundle install --verbose || \
    (echo "First attempt failed, trying with --no-deployment" && \
     bundle config unset deployment && \
     bundle install --verbose)

COPY . .
EOF

    echo "🏗️ Building with gem fixes..."
    DOCKER_BUILDKIT=1 docker build -f Dockerfile.gem-fixes -t e-suchi:gem-fixes .

    if [ $? -eq 0 ]; then
        echo "✅ Build with gem fixes successful!"
        rm Dockerfile.gem-fixes
    else
        echo "❌ Build with gem fixes failed"
        echo "📝 Check Dockerfile.gem-fixes for debugging"
    fi
}

# Fix 5: Quick build commands for common scenarios
quick_build_commands() {
    echo "⚡ Quick build commands for common scenarios:"

    echo "
# 1. Fast development build (30 seconds)
DOCKER_BUILDKIT=1 docker build -f Dockerfile.dev -t e-suchi:dev .

# 2. Production build with retries (2 minutes)
DOCKER_BUILDKIT=1 docker build -t e-suchi:prod .

# 3. Build with more memory (if bundle install OOMs)
DOCKER_BUILDKIT=1 docker build --memory=4g -t e-suchi:prod .

# 4. Build without cache (if gems are cached incorrectly)
DOCKER_BUILDKIT=1 docker build --no-cache -t e-suchi:prod .

# 5. Debug build with full output
DOCKER_BUILDKIT=1 docker build --progress=plain -t e-suchi:debug . 2>&1 | tee build.log
"
}

# Fix 6: Check if base image is accessible
check_base_image() {
    echo "🔍 Checking base image accessibility..."

    if docker pull ghcr.io/sahilas/rails-base:latest; then
        echo "✅ Base image accessible"

        # Test base image
        echo "🧪 Testing base image functionality..."
        docker run --rm ghcr.io/sahilas/rails-base:latest ruby --version
        docker run --rm ghcr.io/sahilas/rails-base:latest bundle --version
        docker run --rm ghcr.io/sahilas/rails-base:latest node --version

    else
        echo "❌ Cannot access base image"
        echo "💡 Make sure you've:"
        echo "   1. Built and pushed the base image"
        echo "   2. Made it public or authenticated to GHCR"
        echo "   3. Used correct image name"
    fi
}

# Main execution
main() {
    case "${1:-help}" in
        "lock")
            fix_gemfile_lock
            ;;
        "config")
            create_bundle_config
            ;;
        "test")
            test_with_base_image
            ;;
        "gems")
            build_with_gem_fixes
            ;;
        "commands")
            quick_build_commands
            ;;
        "check")
            check_base_image
            ;;
        "all")
            fix_gemfile_lock
            create_bundle_config
            check_base_image
            echo "🚀 All fixes applied! Try building now:"
            echo "   DOCKER_BUILDKIT=1 docker build -t e-suchi:prod ."
            ;;
        *)
            echo "Usage: $0 {lock|config|test|gems|commands|check|all}"
            echo ""
            echo "Commands:"
            echo "  lock     - Fix Gemfile.lock platform issues"
            echo "  config   - Create optimized .bundle/config"
            echo "  test     - Test bundle install with base image"
            echo "  gems     - Build with gem-specific fixes"
            echo "  commands - Show quick build commands"
            echo "  check    - Check base image accessibility"
            echo "  all      - Apply all fixes"
            ;;
    esac
}

main "$@"
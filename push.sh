#!/bin/bash
# Fix GHCR permissions and push issues

echo "🔧 Fixing GHCR Permissions and Push Issues"

# Step 1: Check current authentication
check_current_auth() {
    echo "🔍 Checking current Docker authentication..."

    if docker system info | grep -q "Username"; then
        echo "✅ Docker is authenticated"
        docker system info | grep "Username"
    else
        echo "❌ Docker authentication unclear"
    fi

    # Check GHCR specifically
    echo ""
    echo "🔍 Checking GHCR authentication..."
    if grep -q "ghcr.io" ~/.docker/config.json 2>/dev/null; then
        echo "✅ GHCR credentials found in Docker config"
    else
        echo "❌ No GHCR credentials in Docker config"
    fi
}

# Step 2: Create Personal Access Token (if needed)
create_pat_instructions() {
    echo "🎫 Creating Personal Access Token (PAT)"
    echo ""
    echo "1. Go to: https://github.com/settings/tokens"
    echo "2. Click 'Generate new token' → 'Generate new token (classic)'"
    echo "3. Token name: 'Docker GHCR Access'"
    echo "4. Select these scopes:"
    echo "   ✅ write:packages"
    echo "   ✅ read:packages"
    echo "   ✅ delete:packages (optional)"
    echo "   ✅ repo (if repository is private)"
    echo "5. Click 'Generate token'"
    echo "6. Copy the token (starts with ghp_)"
    echo ""
}

# Step 3: Fix authentication
fix_authentication() {
    echo "🔐 Fixing GHCR authentication..."

    # Method 1: Try GitHub CLI
    if command -v gh &> /dev/null; then
        echo "📱 Trying GitHub CLI authentication..."

        if gh auth status &> /dev/null; then
            echo "✅ GitHub CLI is authenticated"

            # Logout from Docker first
            docker logout ghcr.io 2>/dev/null || true

            # Login using GitHub CLI
            if gh auth token | docker login ghcr.io -u sahilas --password-stdin; then
                echo "✅ Successfully logged in with GitHub CLI"
                return 0
            else
                echo "❌ GitHub CLI login failed"
            fi
        else
            echo "❌ GitHub CLI not authenticated"
            echo "Run: gh auth login"
        fi
    fi

    # Method 2: Interactive login with PAT
    echo ""
    echo "🎫 Using Personal Access Token (PAT)..."

    create_pat_instructions

    read -p "Do you have a Personal Access Token? (y/n): " has_token

    if [[ $has_token == "y" || $has_token == "Y" ]]; then
        # Logout first
        docker logout ghcr.io 2>/dev/null || true

        echo "Please login with your PAT (paste token when prompted for password):"
        docker login ghcr.io -u sahilas

        if [ $? -eq 0 ]; then
            echo "✅ Successfully logged in with PAT"
            return 0
        else
            echo "❌ PAT login failed"
        fi
    fi

    return 1
}

# Step 4: Fix repository visibility and permissions
fix_repository_settings() {
    echo "🔧 Repository Settings Check..."
    echo ""
    echo "Please verify these settings on GitHub:"
    echo ""
    echo "1. Repository Visibility:"
    echo "   • Go to: https://github.com/sahilas/rails-base/settings"
    echo "   • Check if repository is Private or Public"
    echo "   • If Private, ensure your PAT has 'repo' scope"
    echo ""
    echo "2. Package Permissions:"
    echo "   • Go to: https://github.com/users/sahilas/packages/container/rails-base/settings"
    echo "   • OR: https://github.com/sahilas/rails-base/pkgs/container/rails-base"
    echo "   • Set visibility to 'Public' or ensure you have write access"
    echo ""
    echo "3. Actions Permissions:"
    echo "   • Go to: https://github.com/sahilas/rails-base/settings/actions"
    echo "   • Enable 'Read and write permissions' for GITHUB_TOKEN"
    echo ""
}

# Step 5: Try alternative build and push method
alternative_build_push() {
    echo "🔄 Trying alternative build and push method..."

    # Build locally first
    echo "🏗️ Building image locally..."
    if docker build -f Dockerfile.base -t rails-base:local .; then
        echo "✅ Local build successful"
    else
        echo "❌ Local build failed"
        return 1
    fi

    # Tag for GHCR
    echo "🏷️ Tagging image..."
    docker tag rails-base:local ghcr.io/sahilas/rails-base:latest

    # Push with retry
    echo "📤 Pushing to GHCR with retry..."

    for attempt in 1 2 3; do
        echo "Push attempt $attempt/3..."

        if docker push ghcr.io/sahilas/rails-base:latest; then
            echo "✅ Successfully pushed latest tag"
        fi

        if [ $attempt -lt 3 ]; then
            echo "⏳ Waiting 10 seconds before retry..."
            sleep 10
        fi
    done

    echo "❌ All push attempts failed"
    return 1
}

# Step 6: Use GitHub Actions instead
use_github_actions() {
    echo "🤖 Alternative: Use GitHub Actions"
    echo ""
    echo "If local push keeps failing, use GitHub Actions:"
    echo ""
    echo "1. Add this workflow to .github/workflows/build-base.yml:"
    echo ""
    cat << 'EOF'
name: Build Base Image
on:
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile.base
          push: true
          tags: |
            ghcr.io/sahilas/rails-base:latest
            ghcr.io/sahilas/rails-base:${{ github.run_number }}
EOF
    echo ""
    echo "2. Commit and push this workflow"
    echo "3. Go to Actions → Build Base Image → Run workflow"
    echo ""
}

# Step 7: Verify the push worked
verify_push() {
    echo "🧪 Verifying pushed image..."

    # Remove local images
    docker rmi ghcr.io/sahilas/rails-base:latest 2>/dev/null || true
    docker rmi rails-base:local 2>/dev/null || true

    # Try to pull
    if docker pull ghcr.io/sahilas/rails-base:latest; then
        echo "✅ Successfully pulled image from GHCR"

        # Test the image
        if docker run --rm ghcr.io/sahilas/rails-base:latest ruby --version; then
            echo "✅ Image works correctly"
            return 0
        else
            echo "❌ Image doesn't work correctly"
        fi
    else
        echo "❌ Failed to pull image from GHCR"
    fi

    return 1
}

# Main execution
main() {
    echo "🚀 GHCR Push Issue Resolver"
    echo "=========================="

    check_current_auth
    echo ""

    # Try to fix authentication
    if fix_authentication; then
        echo ""
        echo "🔄 Attempting build and push..."

        if alternative_build_push; then
            echo ""
            verify_push

            if [ $? -eq 0 ]; then
                echo ""
                echo "🎉 SUCCESS! Base image is now available at:"
                echo "   ghcr.io/sahilas/rails-base:latest"
                echo ""
                echo "You can now use it in your Dockerfiles:"
                echo "   FROM ghcr.io/sahilas/rails-base:latest"
                return 0
            fi
        fi
    fi

    echo ""
    echo "❌ Local push failed. Here are your options:"
    echo ""

    fix_repository_settings
    echo ""

    use_github_actions
    echo ""

    echo "🔧 Common Issues and Solutions:"
    echo ""
    echo "1. 403 Forbidden:"
    echo "   • Check PAT has write:packages scope"
    echo "   • Verify repository/package visibility"
    echo "   • Try docker logout ghcr.io && docker login ghcr.io"
    echo ""
    echo "2. Repository not found:"
    echo "   • Package doesn't exist yet (normal for first push)"
    echo "   • Check repository name spelling"
    echo ""
    echo "3. Authentication issues:"
    echo "   • Use GitHub CLI: gh auth login"
    echo "   • Create new PAT with correct scopes"
    echo "   • Try GitHub Actions instead"
}

# Handle script arguments
case "${1:-main}" in
    "auth")
        fix_authentication
        ;;
    "build")
        alternative_build_push
        ;;
    "verify")
        verify_push
        ;;
    "actions")
        use_github_actions
        ;;
    *)
        main
        ;;
esac
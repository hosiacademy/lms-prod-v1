#!/bin/bash
# LMS Production Image Publisher
# Usage: ./publish-images.sh

set -e

REGISTRY="hosiacademy"
VERSION="v2026.03.12"

echo "========================================"
echo "  LMS Production Image Publisher"
echo "  Version: $VERSION"
echo "========================================"
echo ""

# Check if logged in
if ! docker info 2>&1 | grep -q "Username"; then
    echo "🔐 Not logged in to Docker Hub"
    echo ""
    echo "Please login with one of these commands:"
    echo "  docker login -u hosiacademy"
    echo "  OR"
    echo "  docker login"
    echo ""
    read -p "Press ENTER after logging in..."
fi

echo "✅ Docker Hub connection verified"
echo ""

# Tag images
echo "🏷️  Tagging images..."

docker tag lms-prod-backend:latest $REGISTRY/lms-prod-backend:latest
docker tag lms-prod-backend:latest $REGISTRY/lms-prod-backend:$VERSION
docker tag lms-prod-frontend:latest $REGISTRY/lms-prod-frontend:latest
docker tag lms-prod-frontend:latest $REGISTRY/lms-prod-frontend:$VERSION

echo "✅ Images tagged successfully"
echo ""

# Show images to be pushed
echo "📦 Images to publish:"
echo ""
docker images | grep -E "$REGISTRY.*($VERSION|latest)" | awk '{printf "  • %-40s %-20s %s\n", $1":"$2, $3, $4}'
echo ""

# Confirm push
read -p "🚀 Push images to Docker Hub? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Push cancelled"
    exit 1
fi

# Push backend
echo ""
echo "📤 Pushing backend images..."
docker push $REGISTRY/lms-prod-backend:latest
docker push $REGISTRY/lms-prod-backend:$VERSION

# Push frontend
echo ""
echo "📤 Pushing frontend images..."
docker push $REGISTRY/lms-prod-frontend:latest
docker push $REGISTRY/lms-prod-frontend:$VERSION

echo ""
echo "========================================"
echo "  ✅ Publish Complete!"
echo "========================================"
echo ""
echo "Images published:"
echo "  • $REGISTRY/lms-prod-backend:latest"
echo "  • $REGISTRY/lms-prod-backend:$VERSION"
echo "  • $REGISTRY/lms-prod-frontend:latest"
echo "  • $REGISTRY/lms-prod-frontend:$VERSION"
echo ""
echo "To deploy on production server:"
echo "  1. SSH to production server"
echo "  2. docker pull $REGISTRY/lms-prod-backend:latest"
echo "  3. docker pull $REGISTRY/lms-prod-frontend:latest"
echo "  4. docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d"
echo ""

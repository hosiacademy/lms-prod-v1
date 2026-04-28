#!/bin/bash
set -e

echo "=========================================="
echo "Flutter Web Build for Production"
echo "=========================================="
echo ""
echo "API URL: http://154.66.211.3:7001"
echo "Socket URL: http://154.66.211.3:7001"
echo "Environment: production"
echo ""

cd /home/tk/lms-prod/frontend

# Clean previous build
rm -rf build/web

# Build with same-origin URLs for HTTPS compatibility
echo "Building Flutter web with HTTPS support..."
docker run --rm \
  -v /home/tk/lms-prod/frontend:/app \
  -w /app \
  ghcr.io/cirruslabs/flutter:stable \
  bash -c "flutter clean && flutter pub get && flutter build web --release \
    --dart-define=ENV=production"

echo ""
echo "=========================================="
echo "✅ Build Complete!"
echo "=========================================="
echo ""
echo "Built files: /home/tk/lms-prod/frontend/build/web"
echo ""

# Update prebuilt_web for docker volume
echo "Updating prebuilt_web directory..."
rm -rf /home/tk/lms-prod/frontend/prebuilt_web/*
cp -r /home/tk/lms-prod/frontend/build/web/* /home/tk/lms-prod/frontend/prebuilt_web/

echo "✅ prebuilt_web updated"
echo ""

# Restart frontend container to pick up new files
echo "Restarting frontend container..."
docker restart lms-prod-frontend-1

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "Frontend URL: http://154.66.211.3:7000"
echo "Backend API: http://154.66.211.3:7001"
echo ""
echo "Please refresh your browser (Ctrl+Shift+R) to clear cache"
echo ""

#!/bin/bash
# =============================================================================
# CURRENCY LOCALIZATION FRONTEND DEPLOYMENT SCRIPT
# =============================================================================
# This script rebuilds the Flutter frontend with currency localization
# and deploys it to the production container.
# =============================================================================

set -e

echo "============================================================"
echo "💱 CURRENCY LOCALIZATION FRONTEND DEPLOYMENT"
echo "============================================================"
echo ""

FRONTEND_DIR="/home/tk/lms-prod/frontend"
PREBUILT_DIR="$FRONTEND_DIR/prebuilt_web"
CONTAINER_NAME="lms-prod-frontend-1"

# Step 1: Check Flutter installation
echo "📱 Step 1: Checking Flutter installation..."
cd "$FRONTEND_DIR"
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found in PATH"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -1)
echo "✅ Flutter: $FLUTTER_VERSION"
echo ""

# Step 2: Clean and get dependencies
echo "🔧 Step 2: Cleaning and getting dependencies..."
flutter clean
flutter pub get
echo ""

# Step 3: Build for web
echo "🏗️ Step 3: Building Flutter web app..."
echo "   This may take 5-10 minutes..."
flutter build web --release --base-href="/"
echo ""

# Step 4: Update prebuilt_web folder
echo "📦 Step 4: Updating prebuilt_web folder..."
rm -rf "$PREBUILT_DIR"/*
cp -r "$FRONTEND_DIR/build/web/"/* "$PREBUILT_DIR/"
echo "✅ Prebuilt files copied to: $PREBUILT_DIR"
echo ""

# Step 5: Rebuild Docker container
echo "🐳 Step 5: Rebuilding frontend Docker container..."
cd /home/tk/lms-prod
docker-compose build frontend
echo ""

# Step 6: Restart container
echo "🔄 Step 6: Restarting frontend container..."
docker-compose up -d frontend
echo ""

# Step 7: Verify deployment
echo "✅ Step 7: Verifying deployment..."
sleep 5
if docker ps | grep -q "$CONTAINER_NAME"; then
    echo "✅ Container $CONTAINER_NAME is running"
    
    # Check if CurrencyService is in the build
    if docker exec "$CONTAINER_NAME" grep -q "CurrencyService" /usr/share/nginx/html/main.dart.js; then
        echo "✅ CurrencyService found in build"
    else
        echo "⚠️ CurrencyService NOT found in build"
    fi
else
    echo "❌ Container failed to start"
    exit 1
fi

echo ""
echo "============================================================"
echo "🎉 DEPLOYMENT COMPLETE!"
echo "============================================================"
echo ""
echo "📊 Deployment Summary:"
echo "   • Frontend built: $(date)"
echo "   • Container: $CONTAINER_NAME"
echo "   • Status: Running"
echo ""
echo "🌐 Access the website:"
echo "   • https://www.hosiacademy.africa/"
echo "   • http://localhost:7000"
echo ""
echo "💱 Currency localization features:"
echo "   • IP-based country detection"
echo "   • Auto-convert USD to local currency"
echo "   • 36 African currencies supported"
echo "   • Exchange rates updated daily"
echo ""
echo "🔍 Test the deployment:"
echo "   1. Visit https://www.hosiacademy.africa/"
echo "   2. Check course prices (should show local currency)"
echo "   3. API: curl http://localhost:7001/api/v1/payments/exchange-rates/"
echo "   4. API: curl http://localhost:7001/api/v1/payments/detect-location/"
echo ""
echo "============================================================"

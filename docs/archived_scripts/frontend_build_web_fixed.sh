#!/bin/bash
# Fixed Flutter web build script
set -e

echo "=========================================="
echo "Building Flutter Web (Fixed)"
echo "=========================================="

cd /home/tk/lms-prod/frontend

# Clean everything
echo "Cleaning build artifacts..."
rm -rf build .dart_tool .flutter-plugins* .packages pubspec.lock
docker run --rm -v $(pwd):/app -w /app ghcr.io/cirruslabs/flutter:stable flutter clean

# Step 1: Get dependencies with timeout and retry
echo "Step 1: Getting dependencies..."
for attempt in {1..3}; do
    echo "Attempt $attempt..."
    if docker run --rm -v $(pwd):/app -w /app ghcr.io/cirruslabs/flutter:stable \
        timeout 120 flutter pub get --verbose 2>&1 | grep -q "exiting with code 0"; then
        echo "Dependencies fetched successfully"
        break
    elif [ $attempt -eq 3 ]; then
        echo "Failed to fetch dependencies after 3 attempts"
        exit 1
    fi
    echo "Retrying..."
    sleep 5
done

# Step 2: Validate packages exist
echo "Step 2: Validating packages..."
if ! docker run --rm -v $(pwd):/app -w /app ghcr.io/cirruslabs/flutter:stable \
    sh -c "ls /root/.pub-cache/hosted/pub.dev/shared_preferences*/lib/shared_preferences.dart 2>/dev/null | head -1"; then
    echo "ERROR: Packages not found in pub cache!"
    echo "Attempting to rebuild cache..."
    docker run --rm -v $(pwd):/app -w /app ghcr.io/cirruslabs/flutter:stable \
        sh -c "rm -rf /root/.pub-cache && flutter pub get"
fi

# Step 3: Build web with no wasm dry run
echo "Step 3: Building web..."
docker run --rm \
    -v $(pwd):/app \
    -w /app \
    -e FLUTTER_ROOT=/sdks/flutter \
    ghcr.io/cirruslabs/flutter:stable \
    flutter build web --release \
        --dart-define=API_BASE_URL=http://154.66.211.3:7000 \
        --dart-define=SOCKET_URL=http://154.66.211.3:7000 \
        --dart-define=ENV=production \
        --no-wasm-dry-run \
        --verbose 2>&1 | tail -50

# Step 4: Check if build succeeded
if [ -f "build/web/main.dart.js" ]; then
    echo "=========================================="
    echo "Build succeeded!"
    echo "Output in: build/web/"
    
    # Update prebuilt_web for Docker container
    echo "Updating prebuilt_web..."
    rm -rf prebuilt_web/*
    cp -r build/web/* prebuilt_web/
    
    # Restart frontend container if exists
    if docker ps -a | grep -q lms-prod-frontend; then
        echo "Restarting frontend container..."
        docker restart lms-prod-frontend-1 2>/dev/null || true
    fi
    
    echo "Build complete!"
    echo "Frontend available at: http://154.66.211.3:7000"
else
    echo "=========================================="
    echo "Build failed!"
    echo "Checking for errors..."
    ls -la build/ 2>/dev/null || echo "No build directory"
    exit 1
fi
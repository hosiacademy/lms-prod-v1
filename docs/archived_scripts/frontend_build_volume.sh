#!/bin/bash
# Build with persistent pub cache volume
set -e

echo "Building Flutter web with persistent cache..."
cd /home/tk/lms-prod/frontend

# Create volume for pub cache if doesn't exist
docker volume create flutter-pub-cache 2>/dev/null || true

# Clean build directory
rm -rf build/web

# Run build with volume mount for pub cache
docker run --rm \
  -v flutter-pub-cache:/root/.pub-cache \
  -v $(pwd):/app \
  -w /app \
  ghcr.io/cirruslabs/flutter:stable \
  sh -c "
    echo 'Checking Flutter...'
    flutter --version
    
    echo 'Cleaning...'
    flutter clean
    
    echo 'Getting dependencies...'
    flutter pub get
    
    echo 'Building web...'
    flutter build web --release \
      --dart-define=API_BASE_URL=http://154.66.211.3:7001 \
      --dart-define=SOCKET_URL=http://154.66.211.3:7001 \
      --dart-define=ENV=production \
      --no-wasm-dry-run
  "

if [ -f "build/web/main.dart.js" ]; then
    echo "Build successful!"
    echo "Updating prebuilt_web..."
    rm -rf prebuilt_web/*
    cp -r build/web/* prebuilt_web/
    
    echo "Frontend available at: http://154.66.211.3:7000"
else
    echo "Build failed!"
    exit 1
fi